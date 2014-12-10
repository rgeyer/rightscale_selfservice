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

describe RightScaleSelfService::Api::Service do
  describe "#method_missing" do
    context "called more than once" do
      it "jit initializes the resource & caches it" do
        client = get_mock_client_for_interface()
        service = RightScaleSelfService::Api::Service.new("foo", "1.0", "https://ss", client)
        resource_one = service.bar
        resource_two = service.bar
        expect(resource_one).to be_a RightScaleSelfService::Api::Resource
        expect(resource_two).to be_a RightScaleSelfService::Api::Resource
        expect(resource_one).to equal resource_two
      end
    end

    context "invalid resource supplied" do
      it "raises" do
        client = get_mock_client_for_interface()
        service = RightScaleSelfService::Api::Service.new("foo", "1.0", "https://ss", client)
        expect { service.barbaz }.to raise_error("No resource named \"barbaz\" was found in version \"1.0\" of service \"foo\". Available resources are [foo,bar,baz]")
      end
    end
  end

end
