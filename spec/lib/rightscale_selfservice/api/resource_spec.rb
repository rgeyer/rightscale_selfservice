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

describe RightScaleSelfService::Api::Resource do
  describe "#method_missing" do
    context "invalid action supplied" do
      it "raises" do
        account_id_tokens = RightScaleSelfService::Api::Client.get_known_account_id_tokens
        account_id_tokens.map! {|token| token.gsub(":","")}
        client = get_mock_client_for_interface()
        service = flexmock(:name => "foo", :version => "1.0", :client => client)
        resource = RightScaleSelfService::Api::Resource.new("bar", service)
        expect { resource.foo }.to raise_error("No action named \"foo\" was found on resource \"bar\" in version \"1.0\" of service \"foo\". Available actions are [show,post,#{account_id_tokens.join(",")}]")
      end
    end

    context "parameters supplied" do
      it "encodes and includes them" do
        client = get_mock_client_for_interface()
        client.should_receive(:account_id).and_return("12345")
        service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
        client.should_receive(:get_authorized_rest_client_request)
          .once
          .with(
            FlexMock.hsh(
              :method => :post,
              :url => "http://ss/foo/foo/12345/action",
              :payload => "bar=baz"
            )
          ).and_return(flexmock(:execute => ""))
        api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
        api_resource.post(:id => "12345", :bar => "baz")
      end
    end

    context "third parameter is supplied, and is true" do
      it "returns an unexecuted rest_client request" do
        rest_request = RestClient::Request.new(:method => :get, :url => "https://foo")
        rest_request_mock = flexmock(rest_request)
        rest_request_mock.should_receive(:execute).never
        client = get_mock_client_for_interface()
        client.should_receive(:account_id).and_return("12345")
        service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
        client.should_receive(:get_authorized_rest_client_request)
          .once.with(FlexMock.hsh(:method => :get, :url => "http://ss/foo/12345/foo/action"))
          .and_return(rest_request_mock)
        api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
        request = api_resource.account_id({}, true)
        expect(request).to be_a RestClient::Request
      end
    end

    context "tokens exist in the url which match params" do
      it "replaces them" do
        rest_request = flexmock("rest_request")
        client = get_mock_client_for_interface()
        client.should_receive(:account_id).and_return("12345")
        client.should_receive(:get_authorized_rest_client_request)
          .once.with(FlexMock.hsh(:method => :get, :url => "http://ss/foo/foo/12345", :payload => nil))
          .and_return(rest_request)
        service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
        api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
        request = api_resource.show({"id" => "12345"},true)
      end
    end

    context "one of the request params is a file" do
      it "doesn't url encode anything" do
        file = Tempfile.new("foo")
        client = get_mock_client_for_interface()
        client.should_receive(:account_id).and_return("12345")
        service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
        client.should_receive(:get_authorized_rest_client_request)
          .once
          .with(
            FlexMock.hsh(
              :method => :post,
              :url => "http://ss/foo/foo/12345/action",
              :payload => {:bar => file, :baz => "foo"}
            )
          ).and_return(flexmock(:execute => ""))
        api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
        api_resource.post({:id => "12345", :bar => file, :baz => "foo"}, true)
      end
    end

    context "http verb is get" do
      it "puts parameters in url rather than body" do
        client = get_mock_client_for_interface()
        client.should_receive(:account_id).and_return("12345")
        service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
        account_id_tokens = RightScaleSelfService::Api::Client.get_known_account_id_tokens
        account_id_tokens.map! {|token| token.gsub(":","")}
        account_id_tokens.each do |token|
          client.should_receive(:get_authorized_rest_client_request)
            .once
            .with(
              FlexMock.hsh(
                :method => :get,
                :url => "http://ss/foo/12345/foo/action?foo=yes&bar=baz"
              )
            ).and_return(flexmock(:execute => ""))
          api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
          api_resource.send(token, {:foo => "yes", :bar => "baz"})
        end
      end
    end

    it "replaces all the correct tokens with account id" do
      client = get_mock_client_for_interface()
      client.should_receive(:account_id).and_return("12345")
      service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
      account_id_tokens = RightScaleSelfService::Api::Client.get_known_account_id_tokens
      account_id_tokens.map! {|token| token.gsub(":","")}
      account_id_tokens.each do |token|
        client.should_receive(:get_authorized_rest_client_request)
          .once
          .with(FlexMock.hsh(:method => :get, :url => "http://ss/foo/12345/foo/action"))
          .and_return(flexmock(:execute => ""))
        api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
        api_resource.send(token)
      end
    end

    it "executes the rest request" do
      rest_request = flexmock("rest_request")
      rest_request.should_receive(:execute).once
      client = get_mock_client_for_interface()
      client.should_receive(:account_id).and_return("12345")
      service = flexmock(:name => "foo", :version => "1.0", :client => client, :base_url => "http://ss")
      client.should_receive(:get_authorized_rest_client_request)
        .once.with(FlexMock.hsh(:method => :get, :url => "http://ss/foo/12345/foo/action"))
        .and_return(rest_request)
      api_resource = RightScaleSelfService::Api::Resource.new("foo", service)
      api_resource.account_id
    end
  end
end
