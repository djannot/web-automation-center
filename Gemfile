source 'http://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'

# Use jdbcsqlite3 as the database for Active Record
gem 'activerecord-jdbcsqlite3-adapter'
#gem 'activerecord-jdbcsqlite3-adapter', '1.3.0.beta2' #Because no stable version yet for Rails 4

gem 'zip'

gem 'rubyzip'

# Use SCSS for stylesheets
gem 'sass-rails'#, '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'#, '>= 1.0.3'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'#, '~> 4.0.0'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'#, '~> 1.2'

gem 'threadify'

gem 'jruby-openssl', :platforms => :jruby

gem 'krypt-ossl'

gem 'ruby-hmac'

gem 'google-code-prettify-rails'

gem 'protected_attributes'

gem 'trinidad'#, :require => nil

gem 'warbler'

gem 'excon'#, '~> 0.21.0'

gem 'acts_as_list'#, '~> 0.3.0'

gem 'wadl'

gem 'encrypted_strings'

gem 'yard'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
gem 'bcrypt-ruby', :require => 'bcrypt'

# the javascript engine for execjs gem
platforms :jruby do
  group :assets do
    gem 'therubyrhino'
  end
end
