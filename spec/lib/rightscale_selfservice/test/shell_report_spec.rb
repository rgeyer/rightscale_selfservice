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

describe RightScaleSelfService::Test::ShellReport do
  describe "#progress" do
    context "no templates are finished" do
      it "does not print anything to stdout" do
        templates = [
          flexmock(:state => 'launching', :name => "foo.cat.rb",
            :cases => [flexmock(:type => :compile_only, :result => "SUCCESS")]
          )
        ]
        suite = flexmock(:templates => templates)
        report = RightScaleSelfService::Test::ShellReport.new(suite)
        expect{report.progress}.to_not output.to_stdout
      end
    end

    context "all templates are finished" do
      it "prints finished templates to stdout idempotently" do
        expected_output = <<-EOF
foo.cat.rb: finished
  compile_only: \e[42m\e[30mSUCCESS\e[0m
        EOF
        templates = [
          flexmock(:state => 'finished', :name => "foo.cat.rb",
            :cases => [flexmock(:type => :compile_only, :result => "SUCCESS")]
          )
        ]
        suite = flexmock(:templates => templates)
        report = RightScaleSelfService::Test::ShellReport.new(suite)
        expect{report.progress}.to output(expected_output).to_stdout
        expect{report.progress}.to_not output.to_stdout
      end
    end
  end

  describe "#errors" do
    context "not all templates are finished" do
      it "does not print anything to stdout" do
        templates = [
          flexmock(:state => 'launching', :name => "foo.cat.rb",
            :cases => [flexmock(:type => :compile_only, :result => "SUCCESS")]
          ),
          flexmock(:state => 'finished', :name => "foo.cat.rb",
            :cases => [flexmock(:type => :compile_only, :result => "SUCCESS")]
          )
        ]
        suite = flexmock(:templates => templates)
        report = RightScaleSelfService::Test::ShellReport.new(suite)
        expect{report.errors}.to_not output.to_stdout
      end
    end

    context "all templates are finished" do
      context "no templates or cases have errors" do
        it "does not print anything to stdout" do
          templates = [
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :errors => [])],
              :errors => []
            ),
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :errors => [])],
              :errors => []
            )
          ]
          suite = flexmock(:templates => templates)
          report = RightScaleSelfService::Test::ShellReport.new(suite)
          expect{report.errors}.to_not output.to_stdout
        end
      end

      context "a template has errors" do
        it "prints the errors" do
          expected_output = <<-EOF
\e[41m\e[30mERRORS:\e[0m
\e[31mfoo.cat.rb:
  error
foobarbaz.cat.rb:
  barbaz error 1
  barbaz error 2
\e[0m
          EOF
          templates = [
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :errors => [])],
              :errors => ["error"]
            ),
            flexmock(:state => 'finished', :name => "foobarbaz.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :errors => [])],
              :errors => ["barbaz error 1", "barbaz error 2"]
            )
          ]
          suite = flexmock(:templates => templates)
          report = RightScaleSelfService::Test::ShellReport.new(suite)
          expect{report.errors}.to output(expected_output).to_stdout
        end
      end

      context "a case has errors" do
        it "prints the errors" do
          expected_output = <<-EOF
\e[41m\e[30mERRORS:\e[0m
\e[31mfoo.cat.rb:
  compile_only case:
    error
foobarbaz.cat.rb:
  compile_only case:
    barbaz error 1
    barbaz error 2
\e[0m
          EOF
          templates = [
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :errors => ["error"])],
              :errors => []
            ),
            flexmock(:state => 'finished', :name => "foobarbaz.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :errors => ["barbaz error 1", "barbaz error 2"])],
              :errors => []
            )
          ]
          suite = flexmock(:templates => templates)
          report = RightScaleSelfService::Test::ShellReport.new(suite)
          expect{report.errors}.to output(expected_output).to_stdout
        end
      end
    end
  end

  describe "#failures" do
    context "not all templates are finished" do
      it "does not print anything to stdout" do
        templates = [
          flexmock(:state => 'launching', :name => "foo.cat.rb",
            :cases => [flexmock(:type => :compile_only, :result => "SUCCESS")]
          ),
          flexmock(:state => 'finished', :name => "foo.cat.rb",
            :cases => [flexmock(:type => :compile_only, :result => "SUCCESS")]
          )
        ]
        suite = flexmock(:templates => templates)
        report = RightScaleSelfService::Test::ShellReport.new(suite)
        expect{report.failures}.to_not output.to_stdout
      end
    end

    context "all templates are finished" do
      context "no cases have failures" do
        it "does not print anything to stdout" do
          templates = [
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :failures => [])]
            ),
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :failures => [])]
            )
          ]
          suite = flexmock(:templates => templates)
          report = RightScaleSelfService::Test::ShellReport.new(suite)
          expect{report.failures}.to_not output.to_stdout
        end
      end

      context "a case has failures" do
        it "bring the errors" do
          expected_output = <<-EOF
Failures:
foo.cat.rb:
  compile_only case:
    failure
foobarbaz.cat.rb:
  compile_only case:
    barbaz failure 1
    barbaz failure 2
          EOF
          templates = [
            flexmock(:state => 'finished', :name => "foo.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :failures => ["failure"])],
              :errors => []
            ),
            flexmock(:state => 'finished', :name => "foobarbaz.cat.rb",
              :cases => [flexmock(:type => :compile_only, :result => "SUCCESS", :failures => ["barbaz failure 1", "barbaz failure 2"])],
              :errors => []
            )
          ]
          suite = flexmock(:templates => templates)
          report = RightScaleSelfService::Test::ShellReport.new(suite)
          expect{report.failures}.to output(expected_output).to_stdout
        end
        
      end
    end
  end
end
