require 'yaml'
require 'logger'
require 'rexml/document'
require 'time'

# 設定情報読み出し
def read_config
    yaml = YAML.load_file("config.yml")
    @url = yaml["repo_url"]
    @username = yaml["username"]
    @password = yaml["password"]
    @interval = yaml["interval"]
    @proxy_host = yaml["proxy_host"]
    @proxy_port = yaml["proxy_port"]
    @logger = Logger.new(STDERR)
    @logger.info @url
end

def get_svn_list
  # svnコマンド実行
  svnCmd = "svn"
  svnCmd << " --config-option=servers:global:http-proxy-host=#{@proxy_host}" if !@proxy_host.nil?
  svnCmd << " --config-option=servers:global:http-proxy-port=#{@proxy_port}" if !@proxy_port.nil?
  svnCmd << " --no-auth-cache"
  svnCmd << " --username #{@username}" if !@username.nil?
  svnCmd << " --password #{@password}" if !@password.nil?
  svnCmd << " log"
  svnCmd << " -l 10"
  svnCmd << " --xml"
  svnCmd << " -v"
  svnCmd << " #{@url}"

#  @logger.info svnCmd
  xml = `#{svnCmd}`
  @logger.info xml
  doc = REXML::Document.new(xml)

  xml_hash = {}

  doc.elements.each('log/logentry') do |entry|
    revision = entry.attributes['revision']
    author = entry.elements['author'].text
    date = entry.elements['date'].text
    msg = entry.elements['msg'].text

    ndate = Time.parse(date).getlocal

    entry = { "author"=>author, "date"=>ndate, "msg"=>msg }
    xml_hash[revision] = entry
  end

  xml_hash.each_pair{|key, value|
    @logger.debug key
    @logger.debug value
  }
end

read_config()
get_svn_list()

