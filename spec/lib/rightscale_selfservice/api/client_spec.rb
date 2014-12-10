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

describe RightScaleSelfService::Api::Client do
  describe "#initialize" do
    context "when required parameters are missing" do
      it "raises an exception" do
        expect { client = RightScaleSelfService::Api::Client.new({}) }.to raise_error
      end

      it "lists the supplied params in the exception" do
        expect { client = RightScaleSelfService::Api::Client.new(:account_id => "12345", :something => "foo")}.to raise_error("RightScaleSelfService::Api requires the following parameters (account_id,selfservice_url,api_url) but only these were supplied (account_id,something)")
      end
    end

    context "when no login parameters are provided" do
      it "raises an exception" do
        expect {
          client = RightScaleSelfService::Api::Client.new(:account_id => "12345", :selfservice_url => "", :api_url => "")
        }.to raise_error
      end
    end

    context "when access token is provided for authentication" do
      it "only logs into SS" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).with(
          FlexMock.hsh(
            :url => "https://ss/api/catalog/new_session?account_id=12345",
            :method => :get,
            :headers => {"Authorization" => "Bearer token"}
          )
        ).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
      end
    end

    context "when refresh token is provided for authentication" do
      it "logs into CM and then SS" do
        cmrequestmock = flexmock(:execute => flexmock(:to_s => '{"access_token": "token"}'))
        ssrequestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).with(
          FlexMock.hsh(
            :url => "https://cm/api/oauth2",
            :method => :post,
            :payload => URI.encode_www_form({:grant_type => "refresh_token", :refresh_token => "refresh_token"}),
            :headers => {"X-API-VERSION" => "1.5"}
          )
        ).and_return(cmrequestmock)

        flexmock(RestClient::Request).should_receive(:new).with(
          FlexMock.hsh(
            :url => "https://ss/api/catalog/new_session?account_id=12345",
            :method => :get,
            :headers => {"Authorization" => "Bearer token"}
          )
        ).and_return(ssrequestmock)
        client = RightScaleSelfService::Api::Client.new(
          :refresh_token => "refresh_token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
      end
    end

    context "when email and password is provided for authentication" do
      it "logs into CM and then SS" do
        cmrequestmock = flexmock(:execute => flexmock(:cookies => {"rs_gbl" => "rs_gbl"}))
        ssrequestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).with(
          FlexMock.hsh(
            :url => "https://cm/api/session",
            :method => :post,
            :payload => URI.encode_www_form({:email => "email", :password => "password", :account_href => "/api/accounts/12345"}),
            :headers => {"X-API-VERSION" => "1.5"}
          )
        ).and_return(cmrequestmock)

        flexmock(RestClient::Request).should_receive(:new).with(
          FlexMock.hsh(
            :url => "https://ss/api/catalog/new_session?account_id=12345",
            :method => :get,
            :cookies => {"rs_gbl" => "rs_gbl"}
          )
        ).and_return(ssrequestmock)
        client = RightScaleSelfService::Api::Client.new(
          :email => "email",
          :password => "password",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
      end
    end

  end

  describe "#method_missing" do
    context "version is supplied" do
      it "intializes a service with supplied version" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
        mock_client = flexmock(client)
        mock_client.should_receive(:interface).and_return(
          {
            "services" => {
              "catalog" => {
                "1.0" => {},
                "1.1" => {}
              }
            }
          }
        )
        service = mock_client.catalog("1.0")
        expect(service).to be_a RightScaleSelfService::Api::Service
        expect(service.version).to match "1.0"
      end
    end

    context "no version is supplied" do
      it "initializes a service with the latest version" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
        mock_client = flexmock(client)
        mock_client.should_receive(:interface).at_least.once.and_return(
          {
            "services" => {
              "catalog" => {
                "1.0" => {},
                "1.1" => {}
              }
            }
          }
        )
        service = mock_client.catalog
        expect(service).to be_a RightScaleSelfService::Api::Service
        expect(service.version).to match "1.1"
      end
    end

    context "invalid version supplied" do
      it "raises" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
        mock_client = flexmock(client)
        mock_client.should_receive(:interface).at_least.once.and_return(
          {
            "services" => {
              "catalog" => {
                "1.0" => {},
                "1.1" => {}
              }
            }
          }
        )
        expect { mock_client.catalog("2.0") }.to raise_error(RuntimeError, "Version 2.0 of service \"catalog\" can not be found. Available versions are [1.0,1.1]")
      end
    end

    context "invalid service supplied" do
      it "raises" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
        mock_client = flexmock(client)
        mock_client.should_receive(:interface).at_least.once.and_return(
          {
            "services" => {
              "catalog" => {
                "1.0" => {},
                "1.1" => {}
              },
              "manager" => {
                "1.0" => {},
                "1.1" => {}
              }
            }
          }
        )
        expect { mock_client.foo }.to raise_error(RuntimeError, "No service named \"foo\" can not be found. Available services are [catalog,manager]")
      end
    end

    context "called more than once" do
      it "jit initializes the service & caches it" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
        mock_client = flexmock(client)
        mock_client.should_receive(:interface).at_least.once.and_return(
          get_mock_interface_hash()
        )
        first_service = mock_client.foo
        second_service = mock_client.foo
        expect(first_service).to equal(second_service)
      end
    end

    it "strips slashes from selfservice_url and appends /api/:service_name to the service base_url" do
      4.times do |idx|
        base_url = "https://ss"
        idx.times {|slashes| base_url += "/"}
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => base_url,
          :api_url => "https://cm"
        )
        mock_client = flexmock(client)
        mock_client.should_receive(:interface).at_least.once.and_return(
          get_mock_interface_hash()
        )
        service = client.foo
        expect(service.base_url).to match("https://ss/api/foo")
      end
    end
  end

  describe "#get_relative_href" do
    context "provided a full url with protocol and hostname" do
      it "returns the expected relative href" do
        requestmock = flexmock(:execute => "")
        flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
        client = RightScaleSelfService::Api::Client.new(
          :access_token => "token",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
        relative_href = client.get_relative_href("https://ss/api/service/12345/foo/12345")
        expect(relative_href).to match "/api/service/12345/foo/12345"
      end
    end
  end

end
