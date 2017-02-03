FROM ruby
ENV http_proxy http://192.168.56.102:3128/
ENV https_proxy http://192.168.56.102:3128/
ENV no_proxy 127.0.0.1, 192.168.56.101, localhost
RUN apt-get update && apt-get install -y mysql-client
RUN gem install mysql2 sqlite3 sequel sinatra sinatra-contrib

