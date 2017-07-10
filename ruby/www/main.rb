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

DB = Sequel.sqlite('notify.db')

# テーブルが無かったら作る
# 履歴DB
unless DB.table_exists?(:items)
  DB.create_table :items do
    primary_key :id
    String :revision
    String :author
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

    items = DB[:items] # Create a dataset

    # DBの最新リビジョンから更新があったか比較
    newest = items.max(:revision)
#    logger.debug newest
    logger.debug rev_list.max[0]

    if newest != rev_list.max[0]
      # 更新あり
      logger.debug "repository is update."

      # 新規のリビジョンの個数数え
      rev_list.each_pair{ |key, value|
        if key != newest
          # DBに追加
          items.insert(:revision => key, :author => value[:author], :msg => value[:msg], :fetched => 0)
        end
      }
    end

    sleep config[:internval]
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
  @items = DB[:items].limit(10).all
#  logger.debug @items
  erb :index
end

# REST 通知オブジェクトをjsonで返す
get '/fetch' do
  items = DB[:items]
  myItems = nil
  i = 0
  while (myItems.nil? && i < 10) do
    myItems = items.where(:fetched => 0).first #未通知のレコードのうち最初の1件を取得
#    logger.info myItems
    sleep 2 if myItems.nil?
    i = i + 1
  end

  unless (myItems.nil?) then
#    items.where(:id => myItems[:id]).update(:fetched => 1) # 通知済みレコードのフラグ更新
    str = JSON.generate({"app_name" => myItems[:app_name], "desc" => myItems[:desc], "status" => "success"})
  else
    str = JSON.generate("status" => "data none")
  end

end

