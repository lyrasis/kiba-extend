# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :documentation do
  gem 'redcarpet', '~>3.5' # markdown parser for generating documentation
  gem 'yard', '~>0.9.28'
end

group :development, :test do
  gem 'bundler', '~> 2.3'
  gem 'byebug', '~>11.0'
  gem 'pry', '~> 0.14'
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.11'
  gem 'rubocop', '~> 1.18.4'
  gem 'rubocop-rspec', '~> 2.4.0'
end

group :test do
  gem 'simplecov', require: false
end
# Specify your gem's dependencies in kiba-extend.gemspec
gemspec

gem "yardspec", "~> 0.2.0"
