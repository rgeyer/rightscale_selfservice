Gem::Specification.new do |gem|
  gem.name = "rightscale_selfservice"
  gem.version = "0.0.1"
  gem.homepage = "https://github.com/rgeyer/rightscale_selfservice"
  gem.license = "MIT"
  gem.summary = %Q{A rubygem with a buncha useful CLI bits for RightScale Self Service, including a test harness for Cloud Application Templates}
  gem.description = gem.summary
  gem.email = "me@ryangeyer.com"
  gem.authors = ["Ryan J. Geyer"]
  gem.executables << "rightscale_selfservice"

  gem.add_dependency("thor", "~> 0.19.1")
  gem.add_dependency("rest-client", "~> 1.7.0")

  gem.files = Dir.glob("{lib,bin}/**/*") + ["LICENSE", "README.md"]
end
