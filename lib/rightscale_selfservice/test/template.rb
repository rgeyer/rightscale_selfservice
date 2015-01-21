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
    class Template
      attr_accessor :cases
      attr_accessor :template_string
      # intialized -> launching -> running | failed -> terminating -> finished
      attr_accessor :state

      attr_accessor :errors
      attr_accessor :api_responses

      attr_reader :name

      def initialize(filepath)
        @name = File.basename(filepath)
        self.api_responses = {}
        self.state = "initialized"
        self.errors = []
        self.cases = []
        self.template_string = template_str = RightScaleSelfService::Utilities::Template.preprocess(filepath)
        test_config = {}
        if template_str.include?('#test:compile_only=true')
          self.cases = [RightScaleSelfService::Test::Case.new(:compile_only)]
          self.state = "running"
        else
          execution_state = template_str.match(/^#test:execution_state=(?<state>[0-9a-zA-Z ]*)/)['state']
          options = {:state => execution_state}
          alt_state_matches = template_str.match(/^#test:execution_alternate_state=(?<state>[0-9a-zA-Z ]*)/)
          if alt_state_matches && alt_state_matches.size > 0
            options[:alternate_state] = alt_state_matches['state']
          end
          self.cases << RightScaleSelfService::Test::Case.new(:execution, options)

          template_str.scan(/(#test_operation:.*?)\noperation ["'](.*?)["'] do/m).each do |operation|
            tags = operation[0]
            operation_name = operation[1]

            options = {:operation_name => operation_name}

            execution_state = tags.match(/^#test_operation:execution_state=(?<state>[0-9a-zA-Z ]*)/)['state']
            options[:state] = execution_state
            alt_state_matches = tags.match(/^#test_operation:execution_alternate_state=(?<state>[0-9a-zA-Z ]*)/)
            if alt_state_matches.size > 0
              options[:alternate_state] = alt_state_matches['state']
            end

            tags.scan(/#test_operation_param:(?<key>.*?)=(?<val>.*?)$/).each do |param_pair|
              options[:params] = {} unless options.has_key?(:params)
              options[:params][param_pair[0]] = param_pair[1]
            end

            self.cases << RightScaleSelfService::Test::Case.new(:operation, options)
          end
        end
      end

      def pump(suite)
        case self.state
        when 'initialized'
          begin
            self.api_responses[:execution_create] = suite.api_client.manager.execution.create(:source => self.template_string)
            self.state = 'launching'
          rescue RestClient::ExceptionWithResponse => e
            self.errors << "Failed to create execution from template\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
            self.state = 'failed'
          end
        when 'launching'
          get_execution_status_and_set_as_state(suite)
        when 'running','failed'
          # TODO: Any error handling here?
          unfinished_cases = cases.select {|c| c.pump(suite, self)}
          if unfinished_cases.size == 0
            if self.api_responses.has_key?(:execution_create)
              exec_id = get_execution_id()
              self.api_responses[:terminate_operation_create] =
                suite.api_client.manager.operation.create(
                  :name => 'terminate', :execution_id => exec_id
                )
              self.state = 'terminating'
            else
              self.state = 'terminated'
            end
          end
        when 'terminating'
          get_execution_status_and_set_as_state(suite)
        when 'terminated'
          begin
            exec_id = get_execution_id()
            if exec_id
              suite.api_client.manager.execution.delete(:id => exec_id)
            end
          rescue RestClient::ExceptionWithResponse => e
            self.errors << "Failed to delete execution #{self.api_response[:execution_create][:headers][:location]}\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
          end
          self.state = 'finished'
        when 'finished'
          # Do nothing
        else
          self.errors << "unknown template state #{self.state}"
          self.state = 'finished'
        end
      end

      private

      def get_execution_status_and_set_as_state(suite)
        begin
          exec_id = get_execution_id()
          if exec_id
            self.api_responses[:execution_show] = suite.api_client.manager.execution.show(:id => exec_id)
            json_str = self.api_responses[:execution_show].body
            show = JSON.parse(json_str)
            self.state = show['status']
          end
        rescue RestClient::ExceptionWithResponse => e
          # TODO: Do I want to catch errors here, or let it fall through and
          # let the next pump retry?
          self.errors << "Failed to check execution status\n\n#{RightScaleSelfService::Api::Client.format_error(e)}"
        end
      end

      def get_execution_id
        if self.api_responses.has_key?(:execution_create)
          exec_href = self.api_responses[:execution_create].headers[:location]
          RightScaleSelfService::Api::Client.get_resource_id_from_href(exec_href)
        else
          nil
        end
      end

    end
  end
end
