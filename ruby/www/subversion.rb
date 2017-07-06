require 'yaml'
require 'logger'
require 'rexml/document'
require 'time'
require './config.rb'

def get_svn_list(config, base = nil)
  # svnコマンド実行
  svnCmd = "svn"
  svnCmd << " --config-option=servers:global:http-proxy-host=#{config[:proxy_host]}" if !config[:proxy_host].nil?
  svnCmd << " --config-option=servers:global:http-proxy-port=#{config[:proxy_port]}" if !config[:proxy_port].nil?
  svnCmd << " --no-auth-cache"
  svnCmd << " --username #{config[:username]}" if !config[:username].nil?
  svnCmd << " --password #{config[:password]}" if !config[:password].nil?
  svnCmd << " log"
  svnCmd << " -l 10"
  svnCmd << " --xml"
  svnCmd << " -v"
  svnCmd << " -r #{base}:HEAD" if !base.nil?
  svnCmd << " #{config[:url]}"

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

  return xml_hash
end

@logger = Logger.new(STDERR)

config_hash = read_config()
@logger.info config_hash[:url]

#x_hash = {}
x_hash = get_svn_list(config_hash)
rev = x_hash.keys
rev.sort
@logger.debug rev[0]

x_hash = get_svn_list(config_hash, rev[0])




