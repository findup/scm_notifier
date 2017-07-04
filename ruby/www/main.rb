require 'rubygems'
#require 'bundler'
require 'sequel'
require 'sqlite3'
require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'yaml'
require 'logger'
require 'rexml/document'

#Bundler.require(:default)

DB = Sequel.sqlite('notify.db')

# テーブルが無かったら作る
# 履歴DB
unless DB.table_exists?(:items)
  DB.create_table :items do
    primary_key :id
    String :app_name
    String :desc
    Integer :fetched
  end
end

# 設定情報読み出し
yaml = YAML.load_file("config.yml")
@url = yaml["repo_url"]
@username = yaml["username"]
@password = yaml["password"]
@interval = yaml["interval"]
@proxy_host = yaml["proxy_host"]
@proxy_port = yaml["proxy_port"]
@logger = Logger.new(STDERR)
@logger.info @url

set :bind, '0.0.0.0' # webrick for remote host.

def get_svn_list
  # svnコマンド実行
  svnCmd = "svn"
  svnCmd << " --config-option=servers:global:http-proxy-host=#{@proxy_host}"
  svnCmd << " --config-option=servers:global:http-proxy-port=#{@proxy_port}"
  svnCmd << " --no-auth-cache"
  svnCmd << " --username #{@username}"
  svnCmd << " --password #{@password}"
  svnCmd << " log"
  svnCmd << " -l 5"
  svnCmd << " --xml"
  svnCmd << " -v"
  svnCmd << " #{@url}"

  @logger.info svnCmd
  xml2 = `#{svnCmd}`
  @logger.info xml2
#  doc = REXML::Document.new(xml)
end

# バックグラウンドワーカー
Thread.start do
  loop do
    get_svn_list()
    sleep @interval
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
  items.where(:id => myItems[:id]).update(:fetched => 1) # 通知済みレコードのフラグ更新
  str = JSON.generate({"app_name" => myItems[:app_name], "desc" => myItems[:desc], "status" => "success"})
else
  str = JSON.generate("status" => "data none")
end

#  i = 0
#  stream do |out|
#    while i < 10 do
#      out << str
#      sleep 1
#      i = i + 1
#    end
#  end
end

