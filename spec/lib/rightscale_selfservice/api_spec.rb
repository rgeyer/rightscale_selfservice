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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'helper'))

describe RightScaleSelfService::Api do
  describe "#initialize" do
    context "when required parameters are missing" do
      it "raises an exception" do
        expect { client = RightScaleSelfService::Api.new({}) }.to raise_error
      end

      it "lists the supplied params in the exception" do
        expect { client = RightScaleSelfService::Api.new(:account_id => "12345", :something => "foo")}.to raise_error("RightScaleSelfService::Api requires the following parameters (account_id,selfservice_url,api_url) but only these were supplied (account_id,something)")
      end
    end

    context "when no login parameters are provided" do
      it "raises an exception" do
        expect {
          client = RightScaleSelfService::Api.new(:account_id => "12345", :selfservice_url => "", :api_url => "")
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
        client = RightScaleSelfService::Api.new(
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
        client = RightScaleSelfService::Api.new(
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
        client = RightScaleSelfService::Api.new(
          :email => "email",
          :password => "password",
          :account_id => "12345",
          :selfservice_url => "https://ss",
          :api_url => "https://cm"
        )
      end
    end

  end
end
