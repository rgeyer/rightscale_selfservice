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
    # A base class for behavior shared with all SS API Services.  Today
    # they are (designer,catalog,manager)
    #
    # @see http://support.rightscale.com/12-Guides/Self-Service
    class Service
      attr_accessor :name

      attr_accessor :client

      attr_accessor :version

      attr_accessor :base_url

      def initialize(name, version, base_url, client)
        @resources = {}
        @name = name
        @version = version
        @base_url = base_url
        @client = client
      end

      def method_missing(name, *arguments)
        unless client.interface["services"][@name][@version].has_key?(name.to_s)
          raise "No resource named \"#{name}\" was found in version \"#{@version}\" of service \"#{@name}\". Available resources are [#{client.interface["services"][@name][@version].keys.join(',')}]"
        end

        if @resources.has_key?(name.to_s)
          @resources[name.to_s]
        else
          resource = RightScaleSelfService::Api::Resource.new(name.to_s, self)
          @resources[name.to_s] = resource
        end
      end
    end
  end
end
