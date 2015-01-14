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
  module Api
    class Resource
      attr_accessor :name
      attr_accessor :service

      def initialize(name, service)
        @name = name
        @service = service
      end

      # Finds the specified action and executes it for this resource
      #
      def method_missing(name, *args)
        actions_with_name = @service.client.interface["services"][@service.name][@service.version][@name]["controller"]["actions"].select{|a| a["name"] == name.to_s}
        actions = @service.client.interface["services"][@service.name][@service.version][@name]["controller"]["actions"].map{|a| a["name"]}
        unless actions_with_name.length > 0
          raise "No action named \"#{name}\" was found on resource \"#{@name}\" in version \"#{@service.version}\" of service \"#{@service.name}\". Available actions are [#{actions.join(',')}]"
        end

        action = actions_with_name.first
        method = action["urls"].first.first.downcase.to_sym
        url = @service.base_url
        url += action["urls"].first.last
        tokens = RightScaleSelfService::Api::Client.get_known_account_id_tokens
        tokens.each do |token|
          url.gsub!(token, @service.client.account_id)
        end

        params = {:method => method, :url => url, :headers => {"X_API_VERSION" => @service.version}}
        if args.length > 0
          args[0].each do |k,v|
            if url.include? ":#{k}"
              url.gsub!(":#{k}",v)
              args[0].delete(k)
            end
          end

          if args[0].length > 0
            # Detect if a param is a file, using the same mechanism as
            # rest-client
            #
            # https://github.com/rest-client/rest-client/blob/master/lib/restclient/payload.rb#L33
            if args[0].select{|k,v| v.respond_to?(:path) && v.respond_to?(:read) }.length > 0
              params[:payload] = args[0]
            else
              params[:payload] = URI.encode_www_form(args[0])
            end
          end

          if method == :get && params.has_key?(:payload)
            params[:url] += "?#{params[:payload]}"
            params.delete(:payload)
          end
        end

        request = @service.client.get_authorized_rest_client_request(params)
        if args.length > 1 && args[1]
          request
        else
          response = request.execute
        end
      end
    end
  end
end
