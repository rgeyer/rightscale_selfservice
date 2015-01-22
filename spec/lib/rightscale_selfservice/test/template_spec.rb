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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'helper'))

describe RightScaleSelfService::Test::Template do
  describe "#initialize" do
    it "extracts the filename" do
      suite_mock = flexmock('suite')
      template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'compile_only.cat.rb'))
      template = RightScaleSelfService::Test::Template.new(template_path)
      expect(template.name).to match "compile_only.cat.rb"
    end

    context "compile_only template" do
      it "detects and creates a compile only case" do
        suite_mock = flexmock('suite')
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'compile_only.cat.rb'))
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.cases.size).to equal 1
        expect(template.cases.first.type).to equal :compile_only
      end
    end

    context "compile_only with other tags" do
      it "prioritizes compile_only and ignores everything else" do
        suite_mock = flexmock('suite')
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'compile_only_and_extra.cat.rb'))
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.cases.size).to equal 1
        expect(template.cases.first.type).to equal :compile_only
        expect(template.state).to match "running"
      end
    end

    context "execution state and alternate state tags" do
      it "detects and creates an execution case" do
        suite_mock = flexmock('suite')
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.cases.size).to equal 1
        expect(template.cases.first.type).to equal :execution
        expect(template.cases.first.options).to match({:state => "success", :alternate_state => "failed"})
      end
    end

    context "one operation" do
      it "detects and creates an operation case" do
        suite_mock = flexmock('suite')
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'one_operation.cat.rb'))
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.cases.size).to equal 2

        execution_case = template.cases[0]
        operation_case = template.cases[1]

        expect(execution_case.type).to equal :execution
        expect(execution_case.options).to match({:state => "success", :alternate_state => "failed"})

        expect(operation_case.type).to equal :operation
        expect(operation_case.options).to match({
          :operation_name => "one",
          :state => "success",
          :alternate_state => "failed",
          :params => {"key" => "val","key1" => "val1","key2" => "val2"}
          }
        )
      end
    end

    context "two operation" do
      it "detects and creates two operation cases" do
        suite_mock = flexmock('suite')
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'two_operations.cat.rb'))
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.cases.size).to equal 3
        operation_case1 = template.cases[1]
        operation_case2 = template.cases[2]

        expect(operation_case1.type).to equal :operation
        expect(operation_case1.options).to match({
          :operation_name => "one",
          :state => "success",
          :alternate_state => "failed",
          :params => {"key" => "val","key1" => "val1","key2" => "val2"}
          }
        )

        expect(operation_case2.type).to equal :operation
        expect(operation_case2.options).to match({
          :operation_name => "two",
          :state => "success",
          :alternate_state => "failed",
          :params => {"key" => "val","key1" => "val1","key2" => "val2"}
          }
        )
      end
    end

    context "no tags" do
      it "defaults execution state to running" do
        suite_mock = flexmock('suite')
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'notags.cat.rb'))
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.cases.size).to equal 1
        expect(template.cases.first.type).to equal :execution
        expect(template.cases.first.options[:state]).to match 'running'
      end
    end
  end

  describe "#pump" do
    context "state is initialized" do
      it "launches an execution from the template" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
        execution_mock = flexmock('execution')
        execution_mock.should_receive(:create).once
        manager_mock = flexmock(:execution => execution_mock)
        api_client = flexmock(:manager => manager_mock)
        suite = flexmock(:api_client => api_client)
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.state).to match "initialized"
        template.pump(suite)
        expect(template.state).to match "launching"
      end

      context "create execution fails" do
        it "adds an error and sets status to failed" do
          template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
          res_mock = flexmock(:code => 500, :to_hash => {})
          response = RestClient::Response.create("foo", res_mock, [])
          execution_mock = flexmock('execution')
          execution_mock.should_receive(:create).once.and_raise(RestClient::ExceptionWithResponse, response)
          manager_mock = flexmock(:execution => execution_mock)
          api_client = flexmock(:manager => manager_mock)
          suite = flexmock(:api_client => api_client)
          template = RightScaleSelfService::Test::Template.new(template_path)
          expect(template.state).to match "initialized"
          template.pump(suite)
          expect(template.state).to match "failed"
          expect(template.errors.size).to eql 1
        end
      end
    end

    context "state is launching" do
      it "sets state to execution state" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))

        execution_mock = flexmock('execution')
        manager_mock = flexmock(:execution => execution_mock)
        api_client = flexmock(:manager => manager_mock)
        suite = flexmock(:api_client => api_client)
        execution_show_response = flexmock(:body => '{"status": "foobarbaz"}')
        execution_mock.should_receive(:show)
          .once.with(FlexMock.hsh(:id => "12345"))
          .and_return(execution_show_response)

        template = flexmock(RightScaleSelfService::Test::Template.new(template_path))
        template.api_responses[:execution_create] = flexmock(:headers => {:location => '/api/foo/bar/baz/12345'})
        template.state = "launching"
        template.pump(suite)
        expect(template.state).to match "foobarbaz"
      end

      context "execution status is running or failed" do
        it "pumps all cases" do
          template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
          suite = flexmock('suite')
          case_mock = flexmock('case')
          case_mock.should_receive(:pump).twice.and_return(true)
          template = RightScaleSelfService::Test::Template.new(template_path)
          template.state = "running"
          template.cases = [case_mock]
          template.pump(suite)
          template.state = "failed"
          template.pump(suite)
        end

        context "all pumped cases are finished" do
          context "there is a running execution" do
            it "terminates the execution and sets the state to terminating" do
              template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))

              operation_create_response = flexmock(:headers => {:location => '/api/foo/bar/baz/12345'})
              operation_mock = flexmock('execution')
              operation_mock.should_receive(:create).twice.and_return(operation_create_response)
              manager_mock = flexmock(:operation => operation_mock)
              api_client = flexmock(:manager => manager_mock)

              suite = flexmock(:api_client => api_client)
              case_mock = flexmock('case')
              case_mock.should_receive(:pump).twice.and_return(false)
              template = flexmock(RightScaleSelfService::Test::Template.new(template_path))
              template.api_responses[:execution_create] = flexmock(:headers => {:location => '/api/foo/bar/baz/12345'})
              template.state = "running"
              template.cases = [case_mock]
              template.pump(suite)
              template.state = "failed"
              template.pump(suite)
            end
          end

          context "there is no running execution" do
            it "sets the state to terminated" do
              template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))

              suite = flexmock('suite')
              suite.should_receive(:api_client).never
              case_mock = flexmock('case')
              case_mock.should_receive(:pump).twice.and_return(false)
              template = RightScaleSelfService::Test::Template.new(template_path)
              template.state = "running"
              template.cases = [case_mock]
              template.pump(suite)
              expect(template.state).to match "terminated"
              template.state = "failed"
              template.pump(suite)
              expect(template.state).to match "terminated"
            end
          end
        end
      end
    end

    context "state is terminating" do
      it "sets state to execution state" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))

        execution_mock = flexmock('execution')
        manager_mock = flexmock(:execution => execution_mock)
        api_client = flexmock(:manager => manager_mock)
        suite = flexmock(:api_client => api_client)
        execution_show_response = flexmock(:body => '{"status": "foobarbaz"}')
        execution_mock.should_receive(:show)
          .once.with(FlexMock.hsh(:id => "12345"))
          .and_return(execution_show_response)

        template = flexmock(RightScaleSelfService::Test::Template.new(template_path))
        template.api_responses[:execution_create] = flexmock(:headers => {:location => '/api/foo/bar/baz/12345'})
        template.state = "terminating"
        template.pump(suite)
        expect(template.state).to match "foobarbaz"
      end
    end

    context "state is terminated" do
      it "deletes the execution and sets state to finished" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))

        execution_mock = flexmock('execution')
        execution_mock.should_receive(:delete).once.with(FlexMock.hsh(:id => '12345'))
        manager_mock = flexmock(:execution => execution_mock)
        api_client = flexmock(:manager => manager_mock)
        suite = flexmock(:api_client => api_client)
        template = flexmock(RightScaleSelfService::Test::Template.new(template_path))
        template.api_responses[:execution_create] = flexmock(:headers => {:location => '/api/foo/bar/baz/12345'})
        template.state = "terminated"
        template.pump(suite)
        expect(template.state).to match 'finished'
      end

      context "no execution exists (compile case)" do
        it "sets state to finished" do
          template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))

          suite = flexmock('suite')
          suite.should_receive(:api_client).never

          template = flexmock(RightScaleSelfService::Test::Template.new(template_path))
          template.state = "terminated"
          template.pump(suite)
          expect(template.state).to match "finished"
        end
      end
    end

    context "state is unknown" do
      it "an error is recorded and template is set to finished state" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
        suite = flexmock('suite')
        template = RightScaleSelfService::Test::Template.new(template_path)
        template.state = "foobarbaz"
        template.pump(suite)
        expect(template.state).to match "finished"
        expect(template.errors.size).to equal 1
        expect(template.errors.first).to match "unknown template state foobarbaz"
      end
    end
  end

  describe "#execution_id" do
    context "execution_create api response exists" do
      it "returns expected execution id" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
        suite = flexmock('suite')
        template = RightScaleSelfService::Test::Template.new(template_path)
        template.api_responses[:execution_create] = flexmock(:headers => {:location => "/foo/bar/12345"})
        expect(template.execution_id).to match "12345"
      end
    end

    context "execution_create api response does not exist" do
      it "returns nil" do
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'test', 'foo.cat.rb'))
        suite = flexmock('suite')
        template = RightScaleSelfService::Test::Template.new(template_path)
        expect(template.execution_id).to match nil
      end
    end
  end
end
