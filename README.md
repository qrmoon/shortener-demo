# A simple URL shortener

## Setup

- create a MySQL database and configure the connection in `config.ini`
- create a table with columns `id VARCHAR`, `url VARCHAR` and `uses INTEGER`
- install ruby and rubygems
- run `gem install bundle`
- run `bundle install` to install all required gems

## Running

Run in production with `APP_ENV=production ruby app.rb`
