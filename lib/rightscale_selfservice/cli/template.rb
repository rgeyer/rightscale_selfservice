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
    class Template < Base
      desc "preprocess <filepath>", "Processes <filepath>, #include:/path/to/file statements with file contents. Will create a new file in the same location prefixed with 'processed-', or in the location specified by -o"
      option :o, :banner => "<output filepath>"
      def preprocess(filepath)
        source_filepath = File.expand_path(filepath, Dir.pwd)
        source_filename = File.basename(source_filepath)
        source_dir = File.dirname(source_filepath)
        dest_filepath = @options.has_key?('o') ? File.expand_path(@options['o'], Dir.pwd) : File.join(source_dir, "processed-#{source_filename}")
        result = RightScaleSelfService::Utilities::Template.preprocess(source_filepath)
        File.open(dest_filepath, 'w') {|f| f.write(result)}
      end

      desc "compile <filepath>", "Uploads <filepath> to SS, validating the syntax. Will report errors if any are found."
      def compile(filepath)
        source_filepath = File.expand_path(filepath, Dir.pwd)
        source_filename = File.basename(source_filepath)
        source_dir = File.dirname(source_filepath)
        result = RightScaleSelfService::Utilities::Template.preprocess(source_filepath)
        client = get_api_client()
        client.designer.template.compile(:source => result)
      end
    end
  end
end