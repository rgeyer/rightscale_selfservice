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

describe "/lib/rightscale_selfservice/api/interface.json" do
  it "contains only the expected tokens to be substituted by the account_id" do
    known_tokens = RightScaleSelfService::Api::Client.get_known_account_id_tokens
    requestmock = flexmock(:execute => "")
    flexmock(RestClient::Request).should_receive(:new).and_return(requestmock)
    client = RightScaleSelfService::Api::Client.new(
      :access_token => "token",
      :account_id => "12345",
      :selfservice_url => "https://ss",
      :api_url => "https://cm"
    )
    mock_client = flexmock(client)
    interface = mock_client.interface
    found_tokens = []
    interface["services"].each do |service_name,service_hash|
      service_hash.each do |version_name,version_hash|
        version_hash.each do |resource_name,resource_hash|
          if resource_hash.has_key?("controller")
            resource_hash["controller"]["actions"].each do |action|
              action["urls"].each do |url|
                found_token = url.last.match(/:[a-z_A-Z0-9]*/)
                found_tokens << found_token[0]
              end
            end
          end
        end
      end
    end
    expect(found_tokens.uniq!).to match known_tokens
  end
end
