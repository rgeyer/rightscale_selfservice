# Copyright (c) 2014 Ryan Geyer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Require base.rb first, to satisfy Travis CI
require File.expand_path(File.join(File.dirname(__FILE__), 'base'))

module RightScaleSelfService
  module Cli
    class Template < Base
      desc "preprocess <filepath>", "Processes <filepath>, #include:/path/to/file statements with file contents. Will create a new file in the same location prefixed with 'processed-', or in the location specified by -o"
      option :o, :banner => "<output filepath>"
      def preprocess(filepath)
        source_filepath = File.expand_path(filepath, Dir.pwd)
        source_filename = File.basename(source_filepath)
        source_dir = File.dirname(source_filepath)
        dest_filepath = @options.has_key?('o') ? File.expand_path(@options['o'], Dir.pwd) : File.join(source_dir, "processed-#{source_filename}")

        logger.info("Preprocessing #{source_filepath} and writing result to #{dest_filepath}")

        result = RightScaleSelfService::Utilities::Template.preprocess(source_filepath)
        File.open(dest_filepath, 'w') {|f| f.write(result)}
        logger.info("Done! Find your file at #{dest_filepath}")
      end

      desc "compile <filepath>", "Uploads <filepath> to SS, validating the syntax. Will report errors if any are found."
      def compile(filepath)
        source_filepath = File.expand_path(filepath, Dir.pwd)
        source_filename = File.basename(source_filepath)
        source_dir = File.dirname(source_filepath)
        result = RightScaleSelfService::Utilities::Template.preprocess(source_filepath)
        client = get_api_client()
        logger.info("Uploading #{source_filepath} to validate syntax")
        begin
          client.designer.template.compile(:source => result)
          logger.info("#{source_filepath} compiled successfully!")
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to compile template\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end

      desc "upsert <filepath>", "Upload <filepath> to SS as a new template or updates an existing one (based on name)"
      def upsert(filepath)
        template_href = ""
        source_filepath = File.expand_path(filepath, Dir.pwd)
        source_filename = File.basename(source_filepath)
        source_dir = File.dirname(source_filepath)
        template = RightScaleSelfService::Utilities::Template.preprocess(source_filepath)
        client = get_api_client()

        matches = template.match(/^name\s*"(?<name>.*)"/)
        tmp_file = matches["name"].gsub("/","-").gsub(" ","-")
        name = matches["name"]

        logger.info("Fetching a list of existing templates to see if \"#{name}\" exists...")

        templates = JSON.parse(client.designer.template.index.body)
        existing_templates = templates.select{|t| t["name"] == name }

        tmpfile = Tempfile.new([tmp_file,".cat.rb"])
        begin
          tmpfile.write(template)
          tmpfile.rewind
          if existing_templates.length != 0
            logger.info("A template named \"#{name}\" already exists, updating it...")
            template_id = existing_templates.first()["id"]
            request = client.designer.template.update({:id => template_id, :source => tmpfile}, true)
            response = request.execute
            template_href = client.get_relative_href(request.url)
          else
            logger.info("Creating template \"#{name}\"...")
            response = client.designer.template.create({:source => tmpfile})
            template_href = response.headers[:location]
          end
          logger.info("Successfully upserted \"#{name}\".  Href: #{template_href}")
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to update or create template\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        ensure
          tmpfile.close!()
        end
        template_href
      end

      desc "publish <filepath>", "Update and publish a template (based on name)"
      option :override, :type => :boolean, :default => false, :desc => "When supplied the template will be published even if it already exists in the catalog.  False by default, so an error will be raised if the application already exists."
      def publish(filepath)
        shell = Thor::Shell::Color.new
        template_href = upsert(filepath)
        template_id = template_href.split("/").last
        client = get_api_client()
        logger.info("Publishing template Href: #{template_href}")
        publish_params = {:id => template_id}
        begin
          response = client.designer.template.publish(publish_params)
          logger.info("Successfully published template.")
        rescue RestClient::ExceptionWithResponse => e
          if e.http_code == 409 && @options["override"]
            logger.warn("Template id \"#{template_id}\" has already been published, but --override was set so we'll try to publish again with the overridden_application_href parameter.")
            begin
              app_response = client.catalog.application.index()
              applications = JSON.parse(app_response.body)
              matching_apps = applications.select{|a| a["template_info"]["href"] == template_href}
              if matching_apps == 0
                logger.error(shell.set_color "Unable to find the published application for template id \"#{template_id}\"")
              else
                publish_params[:overridden_application_href] = matching_apps.first["href"]
                retry
              end
            rescue RestClient::ExceptionWithResponse => e
              message = "Failed to get a list of existing published templates\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
              logger.error(shell.set_color message, :red)
            end
          else
            message = "Failed to publish template\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
            logger.error(shell.set_color message, :red)
          end
        end
      end

      desc "list", "Lists all templates"
      option :property, :type => :array, :desc => "When supplied, only the specified properties will be displayed.  By default the entire response is supplied."
      def list
        client = get_api_client()
        begin
          list_response = client.designer.template.index()
          templates = JSON.parse(list_response.body)
          if @options["property"]
            templates.each do |template|
              template.delete_if{|k,v| !(@options["property"].include?(k))}
            end
          end
          puts JSON.pretty_generate(templates)
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to list templates\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end

      desc "execute <filepath>", "Create a new execution (CloudApp) from a template. Optionally supply parameter values"
      option :options_file, :type => :string, :desc => "A filepath to a JSON file containing data which will be passed into the \"options\" parameter of the API call."
      def execute(filepath)
        source_filepath = File.expand_path(filepath, Dir.pwd)
        source_filename = File.basename(source_filepath)
        source_dir = File.dirname(source_filepath)
        result = RightScaleSelfService::Utilities::Template.preprocess(source_filepath)
        client = get_api_client()
        params = {:source => result}
        if @options["options_file"]
          options_filepath = File.expand_path(@options["options_file"], Dir.pwd)
          options_str = File.open(File.expand_path(options_filepath), 'r') { |f| f.read }
          params["options"] = options_str
        end

        begin
          exec_response = client.manager.execution.create(params)
          logger.info("Successfully started execution. Href: #{exec_response.headers[:location]}")
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to create execution from template\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end

    end
  end
end
