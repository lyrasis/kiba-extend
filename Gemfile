# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :documentation do
  gem "kramdown" # markdown parser for generating documentation
  gem "yard"
end

group :documentation, :test do
  gem "yardspec", "~> 0.2.0"
end

group :development do
  gem "debug"
  gem "pry", "~> 0.14"
  gem "almost_standard", github: "kspurgin/almost_standard"
end

group :test do
  gem "rspec"
  gem "simplecov", require: false
end

gemspec
