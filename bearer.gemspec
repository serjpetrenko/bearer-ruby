lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bearer/version"

Gem::Specification.new do |spec|
  spec.name = "bearer"
  spec.version = Bearer::VERSION
  spec.authors = ["Bearer Team<engineering@bearer.sh>"]
  spec.email = ["engineering@bearer.sh"]

  spec.summary = %q{Bearer Ruby}
  spec.description = %q{Ruby client to universally call any API using Bearer.sh}
  spec.homepage = "https://www.bearer.sh"
  spec.licenses = ['MIT']
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.65.0"
  spec.add_development_dependency "pry", "~> 0.12.2"
  spec.add_development_dependency "pry-byebug", "~> 3.7.0"
  spec.add_development_dependency "overcommit", "~> 0.50.0"
  spec.add_development_dependency "webmock", "~> 3.7.6"
  spec.add_development_dependency "solargraph", "~> 0.37.2"
end
