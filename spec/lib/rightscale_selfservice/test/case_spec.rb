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

def get_compile_success_mock
  compile_request_mock = flexmock("compile")
  compile_request_mock.should_receive(:compile).once.with(FlexMock.hsh(:source => ""))
  api_client = flexmock(:designer => flexmock(:template => compile_request_mock))
  suite = flexmock(:api_client => api_client)
  template = flexmock(:template_string => "")
  return suite,template
end

def get_compile_fail_mock(http_code=500,http_body="")
  res_mock = flexmock(:code => http_code, :body => http_body, :to_hash => {})
  response = RestClient::Response.create("foo", res_mock, [])
  compile_request_mock = flexmock("compile")
  compile_request_mock.should_receive(:compile).once.and_raise(RestClient::ExceptionWithResponse, response)
  api_client = flexmock(:designer => flexmock(:template => compile_request_mock))
  suite = flexmock(:api_client => api_client)
  template = flexmock(:template_string => "")
  return suite,template
end

describe RightScaleSelfService::Test::Case do
  describe "#pump" do
    context "compile_only type" do

      it "calls the compile api action and is immutable" do
        suite,template = get_compile_success_mock()
        test_case = RightScaleSelfService::Test::Case.new(:compile_only)
        test_case.pump(suite, template)
        test_case.pump(suite, template)
      end

      context "compile succeeds" do
        it "returns false" do
          suite,template = get_compile_success_mock()
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          expect(test_case.pump(suite, template)).to eql false
        end

        it "marks the case successful" do
          suite,template = get_compile_success_mock()
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          test_case.pump(suite, template)
          expect(test_case.result).to match "SUCCESS"
        end
      end

      context "compile fails" do
        it "returns false" do
          suite,template = get_compile_fail_mock(422)
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          expect(test_case.pump(suite, template)).to eql false
        end

        it "marks the case failed" do
          suite,template = get_compile_fail_mock(422)
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          test_case.pump(suite,template)
          expect(test_case.result).to match "FAILED"
        end

        it "adds a validation failure message" do
          suite,template = get_compile_fail_mock(422)
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          test_case.pump(suite,template)
          expect(test_case.result).to match "FAILED"
          expect(test_case.failures.size).to eq 1
        end
      end

      context "api throws an error besides 422" do
        it "returns false" do
          suite,template = get_compile_fail_mock(500)
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          expect(test_case.pump(suite, template)).to eql false
        end

        it "marks the case errored and adds error" do
          suite,template = get_compile_fail_mock(500,'{"foo":"barbaz"}')
          test_case = RightScaleSelfService::Test::Case.new(:compile_only)
          test_case.pump(suite, template)
          expect(test_case.result).to match "ERROR"
          expect(test_case.errors.size).to eql 1
          expect(test_case.errors.first).to include("HTTP Response Code: 500")
        end
      end

    end

    context "execution type" do
      context "execution_state matched" do
        it "returns false" do
          suite = flexmock('suite')
          template = flexmock('template')
          template.should_receive(:state).once.and_return("running")
          test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "running"})
          expect(test_case.pump(suite,template)).to eql false
        end

        it "marks the case successful" do
          suite = flexmock('suite')
          template = flexmock('template')
          template.should_receive(:state).once.and_return("running")
          test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "running"})
          test_case.pump(suite,template)
          expect(test_case.result).to match "SUCCESS"
        end

        context "and execution_alternate_state is present" do
          it "marks the case fixed" do
            suite = flexmock('suite')
            template = flexmock('template')
            template.should_receive(:state).once.and_return("running")
            test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "running", :alternate_state => "failed"})
            test_case.pump(suite,template)
            expect(test_case.result).to match "FIXED"
          end
        end
      end

      context "execution_state not matched" do
        it "returns false" do
          suite = flexmock('suite')
          template = flexmock('template')
          template.should_receive(:state).once.and_return("running")
          test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "running"})
          expect(test_case.pump(suite,template)).to eql false
        end

        it "marks the case failed" do
          suite = flexmock('suite')
          template = flexmock('template')
          template.should_receive(:state).twice.and_return("running")
          test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "failed"})
          test_case.pump(suite,template)
          expect(test_case.result).to match "FAILED"
        end

        it "adds a validation failure message" do
          suite = flexmock('suite')
          template = flexmock('template')
          template.should_receive(:state).twice.and_return("running")
          test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "failed"})
          test_case.pump(suite,template)
          expect(test_case.result).to match "FAILED"
          expect(test_case.failures.size).to eq 1
          puts test_case.failures.first
        end

        context "and execution_alternate_state is matched" do
          it "marks the case failed (expected)" do
            suite = flexmock('suite')
            template = flexmock('template')
            template.should_receive(:state).times(2).and_return("failed")
            test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "success", :alternate_state => "failed"})
            test_case.pump(suite,template)
            expect(test_case.result).to match "FAILED (EXPECTED)"
          end
        end
      end

      context "execution_alternate_state matched" do
        it "returns false" do
          suite = flexmock('suite')
          template = flexmock('template')
          template.should_receive(:state).times(2).and_return("failed")
          test_case = RightScaleSelfService::Test::Case.new(:execution, {:state => "running", :alternate_state => "failed"})
          expect(test_case.pump(suite,template)).to eql false
        end
      end

    end

    context "operation type" do
      it "is not implemented" do
        pending("It get's implemented")
        fail
      end
    end

    context "unknown type" do
      it "returns false" do
        suite = flexmock('suite')
        template = flexmock('template')
        test_case = RightScaleSelfService::Test::Case.new(:unknown)
        expect(test_case.pump(suite,template)).to eql false
      end

      it "marks the case errored and adds error" do
        suite = flexmock('suite')
        template = flexmock('template')
        test_case = RightScaleSelfService::Test::Case.new(:unknown)
        test_case.pump(suite,template)
        expect(test_case.result).to match "ERROR"
        expect(test_case.errors.size).to eql 1
      end
    end
  end
end
