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

# Require report.rb first, to satisfy Travis CI
require File.expand_path(File.join(File.dirname(__FILE__), 'report'))

module RightScaleSelfService
  module Test
    class ShellReport < Report

      def initialize(suite, options={})
        super(suite,options)
        @reported_templates = []
        @keyword_substitutions = {
          "SUCCESS" => "\e[42m\e[30mSUCCESS\e[0m",
          "FAILED" => "\e[41m\e[30mFAILED\e[0m",
          "FAILED (EXPECTED)" => "\e[43m\e[30mFAILED (EXPECTED)\e[0m",
          "ERROR" => "\e[41m\e[30mERROR\e[0m",
          "FIXED" => "\e[44m\e[30mFIXED\e[0m"
        }
      end

      def progress
        self.suite.templates.each do |template|
          if template.state == "finished" && !@reported_templates.include?(template)
            puts "#{template.name}: #{template.state}"
            template.cases.each do |testcase|
              puts "  #{get_case_type_and_name(testcase)}: #{@keyword_substitutions[testcase.result]}"
            end
            @reported_templates << template
          end
        end
      end

      def errors
        finished_templates = self.suite.templates.select{|t| t.state == "finished"}
        if finished_templates.size == self.suite.templates.size
          to_puts = ""
          self.suite.templates.each do |template|
            cases_with_errors = template.cases.select{|c| c.errors.size > 0}
            if template.errors.size > 0 ||  cases_with_errors.size > 0
              to_puts += "#{template.name}:\n"
            end
            template.errors.each do |error|
              to_puts += "  #{error}\n"
            end
            cases_with_errors.each do |case_with_errors|
              to_puts += "  #{get_case_type_and_name(case_with_errors)}:\n"
              case_with_errors.errors.each do |error|
                to_puts += "    #{error}\n"
              end
            end
          end
          if to_puts.size > 0
            puts "\e[41m\e[30mERRORS:\e[0m"
            puts "\e[31m#{to_puts}\e[0m"
          end
        end
      end

      def failures
        finished_templates = self.suite.templates.select{|t| t.state == "finished"}
        to_puts = ""
        if finished_templates.size == self.suite.templates.size
          to_puts = ""
          self.suite.templates.each do |template|
            cases_with_failures = template.cases.select{|c| c.failures.size > 0}
            if cases_with_failures.size > 0
              to_puts += "#{template.name}:\n"
            end
            cases_with_failures.each do |case_with_fail|
              to_puts += "  #{get_case_type_and_name(case_with_fail)}:\n"
              # TODO: Add details for an operation case type to differentiate
              # them. This is probably an argument for having some of the
              # progress, error, and failure reporting live in the case
              # class, but we don't want the case class to have to know details
              # about how to output. Hrrmnn.
              case_with_fail.failures.each do |failure|
                to_puts += "    #{failure}\n"
              end
            end
          end
          if to_puts.size > 0
            to_puts = "Failures:\n#{to_puts}"
            puts to_puts
          end
        end
      end

      private

      def get_case_type_and_name(test_case)
        retval = test_case.type.to_s
        if test_case.type == :operation
          retval += " (#{test_case.options[:operation_name]})"
        end
        retval
      end

    end
  end
end
