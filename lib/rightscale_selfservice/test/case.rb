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

      def initialize(type, options = {})
        self.type = type
        self.options = options
        self.result = ""
        self.errors = []
        self.failures = []
        self.finished = false
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
        if finished
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
            self.finished = true
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
            self.finished = true
            false
          when :operation
            # TODO: Implement this
          else
            self.result = 'ERROR'
            self.errors << "Unknown test case type (:#{self.type})"
            self.finished = true
            false
          end
        end
      end
    end
  end
end
