# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :documentation do
  gem "redcarpet", "~>3.5" # markdown parser for generating documentation
  gem "yard", "~>0.9.34"
end

group :development, :test do
  gem "byebug", "~>11.0"
  gem "pry", "~> 0.14"
  gem "rake", "~> 13.0"
  gem "rspec"
  gem "almost_standard", github: "kspurgin/almost_standard", branch: "main"
end

group :test do
  gem "simplecov", require: false
  gem "yardspec", "~> 0.2.0"
end

gemspec
