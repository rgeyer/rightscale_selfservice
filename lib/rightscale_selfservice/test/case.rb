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

module RightScaleSelfService
  module Test
    class Case
      attr_accessor :type
      attr_accessor :options
      attr_accessor :result
      attr_accessor :errors
      attr_accessor :finished
      attr_accessor :failures
      # initialized -> running -> completed | ?? -> finished
      attr_accessor :state
      attr_accessor :api_responses

      def initialize(type, options = {})
        self.type = type
        self.options = options
        self.result = ""
        self.errors = []
        self.failures = []
        self.state = 'initialized'
        self.api_responses = {}
      end

      # Performs the test for this case. Returns a boolean indicating if the
      # test is "done" or not.
      #
      # @param suite [RightScaleSelfService::Test::Suite] The suite this test
      #   case belongs to
      # @param template [RightScaleSelfService::Test::Template] The template
      #   this case belongs to
      #
      # @return [bool] True if this case needs to be pumped again, false if
      #   the case has been executed and does not need any further time slices
      def pump(suite, template)
        if result != ""
          false
        else
          case self.type
          when :compile_only
            begin
              suite.api_client.designer.template.compile(:source => template.template_string)
              self.result = 'SUCCESS'
            rescue RestClient::ExceptionWithResponse => e
              if e.http_code == 422
                self.result = 'FAILED'
                self.failures << "Failed to compile template\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
              else
                self.result = 'ERROR'
                self.errors << RightScaleSelfService::Api::Client.format_error(e)
              end
            end
            false
          when :execution
            if self.options[:state] == template.state
              self.result = 'SUCCESS'
              self.result = 'FIXED' if self.options.has_key?(:alternate_state)
            else
              if self.options.has_key?(:alternate_state) && self.options[:alternate_state] == template.state
                self.result = 'FAILED (EXPECTED)'
              else
                self.result = 'FAILED'
                self.failures << "Expected execution end state to be (#{self.options[:state]}) but got execution end state (#{template.state})"
              end
            end
            false
          when :operation
            if template.state == 'running'
              case self.state
              when 'initialized'
                execution_id = template.execution_id
                create_params = {
                  :execution_id => execution_id,
                  :name => self.options[:operation_name]
                }

                if self.options.has_key?(:params)
                  create_params[:options] = self.options[:params]
                end

                begin
                  self.api_responses[:operation_create] = suite.api_client.manager.operation.create(create_params)
                  self.state = 'running'
                rescue RestClient::ExceptionWithResponse => e
                  self.errors << "Failed to create operation #{self.options[:operation_name]} for execution\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
                  self.result = 'ERROR'
                  return false
                end
                true
              when 'running'
                begin
                  operation_id = RightScaleSelfService::Api::Client.get_resource_id_from_href(self.api_responses[:operation_create].headers[:location])
                  if operation_id
                    self.api_responses[:operation_show] = suite.api_client.manager.operation.show(:id => operation_id)
                    json_str = self.api_responses[:operation_show].body
                    show = JSON.parse(json_str)
                    self.state = show['status']['summary']
                  end
                rescue RestClient::ExceptionWithResponse => e
                  # TODO: Do I want to catch errors here, or let it fall through and
                  # let the next pump retry?
                  self.errors << "Failed to check operation status\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
                end
              when 'completed','failed'
                if self.options[:state] == self.state
                  self.result = 'SUCCESS'
                  self.result = 'FIXED' if self.options.has_key?(:alternate_state)
                else
                  if self.options.has_key?(:alternate_state) && self.options[:alternate_state] == self.state
                    self.result = 'FAILED (EXPECTED)'
                  else
                    self.result = 'FAILED'
                    self.failures << "Expected operation end state to be (#{self.options[:state]}) but got execution end state (#{self.state})"
                  end
                end
                false
              else
              end
            elsif template.state == 'failed'
              self.result = 'FAILED'
              self.failures << "Execution failed to start, could not start a new operation."
              false
            else
              self.result = 'ERROR'
              self.errors << "Unexpected execution state #{template.state} while processing operation test case."
              false
            end
          else
            self.result = 'ERROR'
            self.errors << "Unknown test case type (:#{self.type})"
            false
          end
        end
      end
    end
  end
end
