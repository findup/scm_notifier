require 'yaml'

# 設定情報読み出し
def read_config
    yaml = YAML.load_file("config.yml")

    config_hash = {}
    config_hash[:url] = yaml["repo_url"]
    config_hash[:username] = yaml["username"]
    config_hash[:password] = yaml["password"]
    config_hash[:interval] = yaml["interval"]
    config_hash[:proxy_host] = yaml["proxy_host"]
    config_hash[:proxy_port] = yaml["proxy_port"]
    config_hash[:backtrace] = yaml["backtrace"]

    return config_hash
end
