# Copyright (c) 2014 Ryan J. Geyer
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'flexmock'
require 'rspec'

def get_mock_interface_hash()
  interface_hash = {
    "services" => {
      "foo" => {
        "1.0" => {
        }
      }
    }
  }
  account_id_tokens = RightScaleSelfService::Api::Client.get_known_account_id_tokens
  ["foo","bar","baz"].each do |resource|
    interface_hash["services"]["foo"]["1.0"][resource] = {"controller" => {"actions" => []}}
    show_action = {
      "name" => "show",
      "urls" => [
        [
          "GET",
          "/foo/#{resource}/:id"
        ]
      ]
    }
    interface_hash["services"]["foo"]["1.0"][resource]["controller"]["actions"] << show_action
    account_id_tokens.each do |token|
      action = {
        "name" => token.gsub(":",""),
        "urls" => [
          [
            "GET",
            "/foo/#{token}/#{resource}/action"
          ]
        ]
      }
      interface_hash["services"]["foo"]["1.0"][resource]["controller"]["actions"] << action
    end
  end
  interface_hash
end

def get_mock_client_for_interface()
  interface_hash = get_mock_interface_hash()
  client = flexmock(:interface => interface_hash)
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'rightscale_selfservice'))

RSpec.configure do |c|
  c.mock_with(:flexmock)
end
