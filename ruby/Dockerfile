FROM ruby
# docker build時に指定される環境変数をdockerfile内で有効にする
ARG http_proxy
ARG https_proxy
ARG no_proxy
# ENV でコンテナ内の環境変数を設定
ENV http_proxy=$http_proxy https_proxy=$https_proxy no_proxy=$no_proxy
#RUN apt-get update && apt-get install -y mysql-client
#RUN gem install mysql2 sqlite3 sequel sinatra sinatra-contrib
RUN gem install sequel sqlite3 sinatra sinatra-contrib
