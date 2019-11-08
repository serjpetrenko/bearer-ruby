# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in bearer.gemspec
gemspec

group :development do
  gem "rake", "~> 10.0"
  gem "pry", "~> 0.12.2"
  gem "pry-byebug", "~> 3.7.0"
  gem "overcommit", "~> 0.50.0"
  gem "solargraph", "~> 0.37.2"
end

group :ci do
  gem "bundler", "~> 2.0"
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 0.65.0"
  gem "webmock", "~> 3.7.6"
end
