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

require 'rest-client'

module RightScaleSelfService
  class Api
    attr_accessor :selfservice_url

    attr_accessor :api_url

    attr_accessor :logger

    attr_accessor :account_id

    def initialize(params)
      @auth = {"cookie" => {}, "authorization" => {}}
      required_params = [:account_id,:selfservice_url,:api_url]
      # allowed_params = [
      #   :access_token,
      #   :refresh_token,
      #   :account_id,
      #   :selfservice_url,
      #   :api_url,
      #   :email,
      #   :password,
      #   :logger
      # ]

      # Use the defined logger, or log to a blackhole
      if params.include?(:logger)
        @logger = params[:logger]
      else
        @logger = NullLogger.new
      end

      # Validate required properties
      unless (required_params - params.keys()).length == 0
        raise "RightScaleSelfService::Api requires the following parameters (#{required_params.join(',')}) but only these were supplied (#{params.keys().join(',')})"
      end

      @account_id = params[:account_id]
      @selfservice_url = params[:selfservice_url]
      @api_url = params[:api_url]

      if params.include?(:access_token)
        @logger.info("Using pre-authenticated access token")
        @logger.info("Logging into self service @ #{@selfservice_url}")
        ss_login_req = RestClient::Request.new(
          :method => :get,
          :url => "#{@selfservice_url}/api/catalog/new_session?account_id=#{@account_id}",
          :headers => {"Authorization" => "Bearer #{params[:access_token]}"}
        )
        ss_login_resp = ss_login_req.execute
        @auth["authorization"] = {"Authorization" => "Bearer #{params[:access_token]}"}
      end

      if params.include?(:refresh_token)
        # OAuth
        @logger.info("Logging into RightScale API 1.5 using OAuth @ #{@api_url}")
        cm_login_req = RestClient::Request.new(
          :method => :post,
          :payload => URI.encode_www_form({
                                            :grant_type => "refresh_token",
                                            :refresh_token => params[:refresh_token]
                                          }),
          :url => "#{@api_url}/api/oauth2",
          :headers => {"X-API-VERSION" => "1.5"}
        )
        cm_login_resp = cm_login_req.execute
        oauth_token = JSON.parse(cm_login_resp.to_s)["access_token"]
        @logger.info("Logging into self service @ #{@selfservice_url}")
        ss_login_req = RestClient::Request.new(
          :method => :get,
          :url => "#{@selfservice_url}/api/catalog/new_session?account_id=#{@account_id}",
          :headers => {"Authorization" => "Bearer #{oauth_token}"}
        )
        ss_login_resp = ss_login_req.execute
        @auth["authorization"] = {"Authorization" => "Bearer #{oauth_token}"}
      end

      if params.include?(:email) && params.include?(:password)
        @logger.info("Logging into RightScale Cloud Management API 1.5 @ #{@api_url}")
        cm_login_req = RestClient::Request.new(
          :method => :post,
          :payload => URI.encode_www_form({
            :email => params[:email],
            :password => params[:password],
            :account_href => "/api/accounts/#{@account_id}"
          }),
          :url => "#{@api_url}/api/session",
          :headers => {"X-API-VERSION" => "1.5"}
        )
        cm_login_resp = cm_login_req.execute

        @logger.info("Logging into self service @ #{@selfservice_url}")
        ss_login_req = RestClient::Request.new(
          :method => :get,
          :url => "#{@selfservice_url}/api/catalog/new_session?account_id=#{@account_id}",
          :cookies => {"rs_gbl" => cm_login_resp.cookies["rs_gbl"]}
        )
        ss_login_resp = ss_login_req.execute
        @auth["cookie"] = cm_login_resp.cookies
      end

      if @auth == {"cookie" => {}, "authorization" => {}}
        raise "RightScaleSelfService::Api did not authenticate with #{@selfservice_url}.  Make sure you supplied valid login details"
      end
    end

    def get_authorized_rest_client_request(request_params)
      if @auth["cookie"].length > 0
        request_params[:cookies] = @auth["cookie"]
      end

      if @auth["authorization"].length > 0
        if request_params.has_key?(:headers)
          request_params[:headers].merge!(@auth["authorization"])
        else
          request_params[:headers] = @auth["authorization"]
        end
      end

      RestClient::Request.new(request_params)
    end

  end
end
