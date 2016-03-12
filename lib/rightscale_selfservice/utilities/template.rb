# Copyright (c) 2014-2016 Ryan Geyer
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

require 'yaml'

module RightScaleSelfService
  module Utilities
    class Template
      # Validates that the specified file exists, raising an error if it does not.
      # Then reads the file into a string which is returned
      #
      # @param file [String] the path to the file which should be returned as a string
      #
      # @raise [Errno::ENOENT] If the file does not exist
      # @return [String] the content of the supplied file
      def self.file_to_str_and_validate(file)
        cat_str = File.open(File.expand_path(file), 'r') { |f| f.read.force_encoding('UTF-8') }
      end

      # Returns a de duped hash of files to include by recursively parsing and
      # looking for #include:<relative file path> in the file and all included
      # files.
      #
      # @param file [String] the path of the file to parse for includes
      #
      # @raise [Errno::ENOENT] if the specified file, or any included files do
      #   not exist
      #
      # @return [Hash] a de duped hash of include files, where the key is the
      #   fully qualified path and filename, and the values are the relative
      #   path supplied in the include statement.
      def self.get_include_list(file)
        dedupe_include_list = {}
        contents = file_to_str_and_validate(file)
        contents.scan(/#include:(.*)$/).each do |include|
          include_filepath = File.expand_path(include.first, File.dirname(file))
          dedupe_include_list.merge!({include_filepath => include.first})
          # This merges only the new keys by doing a diff
          child_includes_hash = get_include_list(include_filepath)
          new_keys = child_includes_hash.keys() - dedupe_include_list.keys()
          merge_these = child_includes_hash.select {|k,v| new_keys.include?(k) }
          dedupe_include_list.merge!(merge_these)
        end
        dedupe_include_list
      end

      def self.preprocess(file)
        parent_template = file_to_str_and_validate(file)
        dedup_include_list = get_include_list(file)

        dedup_include_list.each do |key,val|
          include_filepath = key
          include_contents = <<EOF
###############################################################################
# BEGIN Include from #{val}
###############################################################################
EOF

          include_contents += file_to_str_and_validate(key)

          include_contents += <<EOF
###############################################################################
# END Include from #{val}
###############################################################################
EOF

          parent_template.sub!("#include:#{val}",include_contents)
        end
        # Clear all include lines from templates which were included from other templates
        parent_template.gsub!(/#include:(.*)$/,"")
        parent_template
      end

    end
  end
end
