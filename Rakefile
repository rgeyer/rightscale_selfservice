require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'rake/clean'
require 'rest-client'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

desc 'Package gem'
gemtask = Gem::PackageTask.new(Gem::Specification.load('rightscale_selfservice.gemspec')) do |package|
  package.package_dir = 'pkg'
  package.need_zip = true
  package.need_tar = true
end

directory gemtask.package_dir

CLEAN.include(gemtask.package_dir)

require 'yard'
YARD::Rake::YardocTask.new do |t|

end

# == Unit tests == #
spec_opts_file = File.expand_path(File.join(File.dirname(__FILE__),"spec","spec.opts"))
RSPEC_OPTS = ['--options', spec_opts_file]

desc 'Run unit tests'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = RSPEC_OPTS
end

task :default => :spec

def to_camel_case(source)
  # Thanks http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
  source.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
end

desc "Scrapes the current API docs to determine the current interface and put it in a json file"
task :update_interface_json do
  base_url = "https://s3.amazonaws.com/rs_api_docs/selfservice"
  services = ["catalog","designer","manager"]
  hashything = {:services => Hash[services.map{|s| [s, {}]}]}
  services.each do |service|
    service_req = RestClient::Request.new(
      :method => :get,
      :url => "#{base_url}/#{service}/docs/index.json"
    )
    service_resp = service_req.execute
    service_hash = JSON.parse(service_resp.body)
    service_hash.each do |service_version,service_value_hash|
      service_value_hash = Hash[service_value_hash.map {|k,v| [to_camel_case(k),v]}]
      hashything[:services][service][service_version] = service_value_hash
      service_value_hash.each do |k,v|
        camel_case_resource = to_camel_case(k)
        if v.has_key? "controller"
          resource_req = RestClient::Request.new(
            :method => :get,
            :url => "#{base_url}/#{service}/docs/#{service_version}/resources/#{v["controller"]}.json"
          )
          resource_resp = resource_req.execute
          resource_hash = JSON.parse(resource_resp.body)
          resource_hash.merge!(:name => k)
          hashything[:services][service][service_version][camel_case_resource]["controller"] = resource_hash
        end

        if (v.keys & ["media_type","kind"]).length > 0
          key = v.has_key?("media_type") ? "media_type" : "kind"
          type_req = RestClient::Request.new(
            :method => :get,
            :url => "#{base_url}/#{service}/docs/#{service_version}/types/#{v[key]}.json"
          )
          type_resp = type_req.execute
          type_hash = JSON.parse(type_resp.body)
          hashything[:services][service][service_version][camel_case_resource][key] = type_hash
        end
      end
    end
  end

  interface_filename = File.expand_path(File.join(File.dirname(__FILE__),"lib","rightscale_selfservice","api","interface.json"))

  File.open(interface_filename, "w") {|f| f.write JSON.pretty_generate(hashything)}
end
