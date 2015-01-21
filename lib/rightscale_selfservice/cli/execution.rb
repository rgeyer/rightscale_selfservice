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
    class Execution < Base
      desc "list", "List all executions (CloudApps)"
      option :property, :type => :array, :desc => "When supplied, only the specified properties will be displayed.  By default the entire response is supplied."
      def list
        client = get_api_client()

        begin
          response = client.manager.execution.index
          executions = JSON.parse(response.body)
          if @options["property"]
            executions.each do |execution|
              execution.delete_if{|k,v| !(@options["property"].include?(k))}
            end
          end
          puts JSON.pretty_generate(executions)
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to list executions\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end

      desc "show <id_or_href>", "Gets details about an execution (CloudApp) specified by <id_or_href>"
      option :view, :type => :string, :default => 'default', :desc => "Which view to use, one of [default,expanded,source] default is 'default'."
      option :property, :type => :array, :desc => "When supplied, only the specified properties will be displayed. By default the entire response is supplied. Ignored if view is 'source'"
      def show(id_or_href)
        client = get_api_client()
        id = RightScaleSelfService::Api::Client.get_resource_id_from_href(id_or_href)

        begin
          response = client.manager.execution.show(:id => id, :view => @options["view"])
          execution = JSON.parse(response.body)
          if @options["property"] && @options["view"] != "source"
            execution.delete_if{|k,v| !(@options["property"].include?(k))}
          end
          puts JSON.pretty_generate(execution)
        rescue RestClient::ExceptionWithResponse => e
          shell = Thor::Shell::Color.new
          message = "Failed to show execution id #{id}\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          logger.error(shell.set_color message, :red)
        end
      end

    end
  end
end
