require 'rubygems'
#require 'bundler'
require 'sequel'
#require 'sqlite3'
require 'sinatra'
require 'sinatra/reloader'

#Bundler.require(:default)

#DB = Sequel.connect('sqlite://test.db')
DB = Sequel.connect('mysql2://mysql_user:mysql_pw@mysql/mysql_database')

DB.create_table :items do
  primary_key :id
  String :name
  Integer :price
end

set :bind, '0.0.0.0' # webrick for remote host.

# デフォルトルート
get '/' do
  "Hello sinatra"
end
