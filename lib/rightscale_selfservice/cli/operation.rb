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
    class Operation < Base
      desc "create <operation_name> <execution_id_or_href>", "Creates a new operation with the name <operation_name> on the execution specified by <execution_id_or_href>.  Optionally pass input parameters using --options-file."
      option :options_file, :type => :string, :desc => "A filepath to a JSON file containing data which will be passed into the \"options\" parameter of the API call."
      def create(operation_name, execution_id_or_href)
        execution_id = execution_id_or_href.split("/").last
        client = get_api_client()
        params = {:execution_id => execution_id, :name => operation_name}
        if @options["options_file"]
          options_filepath = File.expand_path(@options["options_file"], Dir.pwd)
          options_str = File.open(File.expand_path(options_filepath), 'r') { |f| f.read }
          params["options"] = options_str
        end

        begin
          response = client.manager.operation.create(params)
          logger.info("Successfully started operation \"#{operation_name}\" on execution id \"#{execution_id}\". Href: #{response.headers[:location]}")
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to create operation \"#{operation_name}\" on execution id \"#{execution_id}\"\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end

      desc "list", "Lists all operations, optionally filtered by --filter and/or --property"
      option :filter, :type => :array, :desc => "Filters to apply see (http://reference.rightscale.com/selfservice/manager/index.html#/1.0/controller/V1::Controller::Operation/index)"
      option :property, :type => :array, :desc => "When supplied, only the specified properties will be displayed. By default the entire response is supplied."
      def list()
        params = {}
        if @options["filter"]
          params[:filter] = @options["filter"]
        end

        begin
          client = get_api_client()
          response = client.manager.operation.index(params)
          operations = JSON.parse(response.body)
          if @options["property"]
            operations.each do |op|
              op.delete_if{|k,v| !(@options["property"].include?(k))}
            end
          end
          puts JSON.pretty_generate(operations)
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to list operations\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end
    end
  end
end
