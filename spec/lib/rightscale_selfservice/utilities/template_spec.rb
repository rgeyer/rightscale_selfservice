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

describe RightScaleSelfService::Utilities::Template do
  describe "#file_to_str_and_validate" do
    context "file does not exist" do
      it "raises an exception" do
        expect { RightScaleSelfService::Utilities::Template.file_to_str_and_validate("foo") }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "#get_include_list" do
    it "dedupes nested includes" do
      file = File.expand_path(
        File.join(
          File.dirname(__FILE__),
          '..',
          '..',
          '..',
          'templates',
          'dedupe_include.cat.rb'
        )
      )
      list = RightScaleSelfService::Utilities::Template.get_include_list(file)
      expect(list.values.size).to equal(2)
      expect(list.values).to include("includes/base.cat.rb")
      expect(list.values).to include("includes/level1.cat.rb")
    end
  end

  describe "#preprocess" do
    context "single non nested include" do
      it "produces expected output" do
        file = File.expand_path(
          File.join(
            File.dirname(__FILE__),
            '..',
            '..',
            '..',
            'templates',
            'single_include.cat.rb'
          )
        )
        processed = RightScaleSelfService::Utilities::Template.preprocess(file)
        expected_output = <<EOF
name "single_include"
rs_ca_ver 20131202
short_description ""

###############################################################################
# BEGIN Include from includes/base.cat.rb
###############################################################################
define base() do

end
###############################################################################
# END Include from includes/base.cat.rb
###############################################################################

EOF

        expect(processed).to match(expected_output)
      end
    end
  end
end
