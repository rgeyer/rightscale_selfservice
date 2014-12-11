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
  module Api
    # @!attribute [rw] selfservice_url
    #   @return [String] URL to use for Self Service API requests.
    #     I.E. https://selfservice-4.rightscale.com
    # @!attribute [rw] api_url
    #   @return [String] URL to use for Cloud Management API requests. Only
    #     used once to authenticate.
    # @!attribute [rw] logger
    #   @return [Logger] A logger which will be used, mostly for debug
    #     purposes
    # @!attribute [rw] account_id
    #   @return [String] A RightScale account id
    # @!attribute [r] interface
    #   @return [Hash] interface A hash containing details about the services,
    #     resources, and actions available in this client.
    class Client

      # A list of tokens which might appear in hrefs which need to be replaced
      # with the RightScale account_id.  This will likely change over time and
      # some of these will likely go away or change meaning
      #
      # @return [Array<String>]
      def self.get_known_account_id_tokens
        [":account_id",":catalog_id",":collection_id",":project_id"]
      end

      attr_accessor :selfservice_url

      attr_accessor :api_url

      attr_accessor :logger

      attr_accessor :account_id

      attr_reader :interface


      # @param params [Hash] a hash of parameters where the possible values are
      #   * account_id [String] (required) A RightScale account id
      #   * selfservice_url [String] (required) URL to use for Self Service API
      #     requests.  I.E. https://selfservice-4.rightscale.com
      #   * api_url [String] (required) URL to use for Cloud Management API
      #     requests. Only used once to authenticate.
      #     I.E. https://us-4.rightscale.com
      #   * access_token [String] A RightScale API OAuth Access Token
      #   * refresh_token [String] A RightScale API OAuth Refresh Token, which
      #     will be exchanged for an access token
      #   * email [String] A RightScale user email address
      #   * password [String] A RightScale user password
      #   * logger [Logger] A logger which will be used, mostly for debug purposes
      def initialize(params)
        @services = {}
        @auth = {"cookie" => {}, "authorization" => {}}
        required_params = [:account_id,:selfservice_url,:api_url]

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

        interface_filepath = File.expand_path(File.join(File.dirname(__FILE__),"interface.json"))
        interface_file = File.open(interface_filepath, "rb")
        begin
          @interface = JSON.parse(interface_file.read)
        rescue Exception => e
          raise e
        ensure
          interface_file.close
        end
      end

      # Accepts request parameters and returns a Rest Client Request which has
      # necessary authentication details appended.
      #
      # @param request_params [Hash] A hash of params to be passed to
      #   RestClient::Request.new after it has had API authentication details
      #   injected
      #
      # @return [RestClient::Request] A request which is ready to be executed
      #   cause it's got necessary authentication details
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

      # Returns a service of the specified (or newest) version
      #
      # @param name [String] The name of the desired service
      #
      # @return [RightScaleSelfService::Api::Service]
      #
      # @example Get latest version (1.0) of designer service
      #   service = client.designer
      #   service.version #=> "1.0"
      # @example Get specified version of designer service
      #   service = client.designer("1.1")
      #   service.version #=> "1.1"
      def method_missing(name, *args)
        unless interface["services"].has_key?(name.to_s)
          raise "No service named \"#{name}\" can not be found. Available services are [#{interface["services"].keys.join(',')}]"
        end
        version = ""
        if args.length > 0
          version = args.first
          unless interface["services"][name.to_s].has_key? version
            raise "Version #{version} of service \"#{name}\" can not be found. Available versions are [#{interface["services"][name.to_s].keys.join(',')}]"
          end
        else
          version = interface["services"][name.to_s].keys.sort.last
        end
        service_hash_key = "#{name}::#{version}"

        if @services.has_key?(service_hash_key)
          @services[service_hash_key]
        else
          base_url = selfservice_url.gsub(/\/*$/,"")
          base_url += "/api/#{name}"
          service = RightScaleSelfService::Api::Service.new(name.to_s,version,base_url,self)
          @services[service_hash_key] = service
        end
      end

      # Converts the input param to a relative href.
      # I.E. /api/service/:account_id/resource
      #
      # @param url [String] The full url to get the relative href from
      #
      # @return [String] A relative href
      def get_relative_href(url)
        url.gsub!(@selfservice_url,"")
      end

      # Accepts various possible responses and formats it into useful error text
      #
      # @param [RestClient::ExceptionWithResponse] error The response or error
      #   to format
      def self.format_error(error)
        formatted_text = ""
        if error
          if error.is_a?(RestClient::ExceptionWithResponse)
            formatted_text = "HTTP Response Code: #{error.http_code}\nMessage:\n"
            if error.response.headers[:content_type] == "application/json"
              formatted_text += JSON.pretty_generate(
                JSON.parse(error.response.body)
              ).gsub('\n',"\n")
            else
              formatted_text += error.response.body
            end
          end
        else
          formatted_text = "Nothing supplied for formatting"
        end
        formatted_text
      end

    end
  end
end
