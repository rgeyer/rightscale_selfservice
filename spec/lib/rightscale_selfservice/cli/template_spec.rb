# Copyright (c) 2016 Ryan Geyer
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

describe RightScaleSelfService::Cli::Template do
  describe "#upsert" do
    context "when the template has it's name in single quotes" do
      it "successfully finds the name" do
        client = get_mock_client_for_interface()
        designer_mock = flexmock('designer')
        designer_mock.should_receive(:template).and_return(
          flexmock(
            :index => flexmock(:body => "[]"),
            :create => flexmock(:headers => {:location => "https://ss/api/"})
          )
        )
        client.should_receive(:designer).and_return(designer_mock)
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'single_quote_name.cat.rb'))
        template = flexmock(RightScaleSelfService::Cli::Template.new())
        template.should_receive(:get_api_client).and_return(client)
        template.should_receive(:logger).and_return(Logger.new("/dev/null"))
        template.upsert(template_path)
      end
    end

    context "when the template has it's name in double quotes" do
      it "successfully finds the name" do
        client = get_mock_client_for_interface()
        designer_mock = flexmock('designer')
        designer_mock.should_receive(:template).and_return(
          flexmock(
            :index => flexmock(:body => "[]"),
            :create => flexmock(:headers => {:location => "https://ss/api/"})
          )
        )
        client.should_receive(:designer).and_return(designer_mock)
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'double_quote_name.cat.rb'))
        template = flexmock(RightScaleSelfService::Cli::Template.new())
        template.should_receive(:get_api_client).and_return(client)
        template.should_receive(:logger).and_return(Logger.new("/dev/null"))
        template.upsert(template_path)
      end
    end

    context "when the template does not have a name, or it cannot be found" do
      it "raises a useful error" do
        shell = Thor::Shell::Color.new
        message = "Unable to find the \"name\" property of the CAT. Make sure you have added the necessary header to your CAT file."
        error_with_color = shell.set_color message, :red
        client = get_mock_client_for_interface()
        logger = flexmock('logger')
        logger.should_receive(:error).once.with(error_with_color)
        designer_mock = flexmock('designer')
        designer_mock.should_receive(:template).and_return(
          flexmock(
            :index => flexmock(:body => "[]"),
            :create => flexmock(:headers => {:location => "https://ss/api/"})
          )
        )
        client.should_receive(:designer).and_return(designer_mock)
        template_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates', 'empty.cat.rb'))
        template = flexmock(RightScaleSelfService::Cli::Template.new())
        template.should_receive(:get_api_client).and_return(client)
        template.should_receive(:logger).and_return(logger)
        template.upsert(template_path)
      end
    end
  end
end
