source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'oauth2', github: 'oauth-xx/oauth2'

# Specify your gem's dependencies in agx.gemspec
gemspec
