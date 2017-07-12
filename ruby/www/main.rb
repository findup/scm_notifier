require 'rubygems'
#require 'bundler'
require 'sequel'
require 'sqlite3'
require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'logger'
require 'rexml/document'

require './subversion.rb'

#Bundler.require(:default)

logger = Logger.new(STDERR)

DB = Sequel.sqlite('revision.db')

# テーブルが無かったら作る
# 履歴DB
unless DB.table_exists?(:revisions)
  DB.create_table :revisions do
    Integer :revision , :primary_key=>true
    String :author
    String :date
    String :msg
    Integer :fetched
  end
end

config = read_config()

set :bind, '0.0.0.0' # webrick for remote host.

# バックグラウンドワーカー
Thread.start do

  base_rev = 1

  loop do
    rev_list = {}
    rev_list = get_svn_list(config, base_rev)

    items = DB[:revisions] # Create a dataset

    # DBの最新リビジョンから更新があったか比較
    newest = items.max(:revision)
#    logger.debug newest
    logger.debug rev_list.max[0]

    if newest != rev_list.max[0]
      # 更新あり
      logger.debug "repository is update."

      # 新規のリビジョンの個数数え
      rev_list.each_pair{ |key, value|
        if items.where(:revision => key).count == 0
          # DBに追加
          items.insert(:revision => key, :author => value[:author], :date => value[:date], :msg => value[:msg], :fetched => 0)
        end
      }
    end

    sleep config[:interval]
  end
end

# デフォルトルート
get '/' do
  "Hello sinatra"
end

=begin
# メッセージ追加受付REST
get '/notify' do
  app_name = params['app_name'] #アプリ名
  desc = params['desc'] #本文

  # DBに追加
  items = DB[:items] # Create a dataset
  # Populate the table
  items.insert(:app_name => app_name, :desc => desc, :fetched => 0)
  # WEB APIを叩くだけなのでレスポンスする中身は特になし
  status 200
  body ''
end
=end

# 通知リスト取得、通知トリガ
get '/list' do
  @items = DB[:revisions].order(Sequel.desc(:revision)).limit(config[:backtrace]).all
  erb :index
end

# REST 通知オブジェクトをjsonで返す
get '/fetch' do
  base_rev = params['base_rev']  # クライアント側判断基準
  logger.debug "base_rev:" + base_rev.to_s

  items = DB[:revisions]
  if base_rev.nil?
    # base_rev が存在しない(初回、もしくはリロード時）はnotificationを出さないようにする
    newest_rev = items.max(:revision)
    str = JSON.generate({"newest_rev" => newest_rev, "status" => "first"})
  else
    myItems = items.where(Sequel.lit('revision > ?', base_rev)).all
    newest_rev = items.max(:revision)

    #自リビジョンより新しいレコード
    if myItems.length > 1
      str = JSON.generate({"author" => "", "msg" => "#{myItems.length}個の更新がありました", "newest_rev" => newest_rev, "status" => "success"})
    elsif myItems.length == 1
      # 新規が1件
      str = JSON.generate({"author" => myItems.first[:author], "msg" => myItems.first[:msg], "newest_rev" => newest_rev, "status" => "success"})
    else
      # 更新なし
      str = JSON.generate("newest_rev" => newest_rev, "status" => "data none")
    end
  end

logger.debug str

  return str
end

# setting screen
get '/settings' do


end
