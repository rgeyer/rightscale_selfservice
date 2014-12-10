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
  module Cli
    class Base < Thor
      class_option :auth_hash, :type => :hash, :banner => "<auth-hash>", :desc => "A hash of auth parameters in the form (email:foo@bar.baz password:password account_id:12345)"
      class_option :auth_file, :banner => "<auth-filepath>", :desc => "A yaml file containing auth parameters to use for authentication"

      no_commands {
        def get_api_client()
          client_auth_params = {}
          thor_shell = Thor::Shell::Color.new
          unless @options.keys.include?('auth_file') | @options.keys.include?('auth_hash')
            message = <<EOF
  You must supply authentication details as either a hash or
  a yaml authentication file!
EOF
            thor_shell.say(thor_shell.set_color(message, :red))
            exit 1
          end
          if @options['auth_file']
            client_auth_params = YAML.load_file(File.expand_path(@options['auth_file'], Dir.pwd))
          end

          if @options['auth_hash']
            # Thanks - http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
            client_auth_params = @options['auth_hash'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
          end

          RightScaleSelfService::Api::Client.new(client_auth_params)
        end
      }
    end
  end
end
