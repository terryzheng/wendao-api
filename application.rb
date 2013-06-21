require 'rubygems'

# Set rack environment
ENV['RACK_ENV'] ||= "development"

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require(:default, ENV['RACK_ENV'])

register Sinatra::Synchrony
configure do
  set :run,             false
  set :show_exceptions, ENV["RACK_ENV"]!="production"
  set :raise_errors,    ENV["RACK_ENV"]!="production"
  #不需要处理静态文件，交给nginx做
  set :static,          false
end

#暂时不加web日志，并在mongoid.yml中取消掉mongoid的日志
#    if ENV["RACK_ENV"]=="production"
#      logger = ::Logger.new("logs/api.log")
#      logger.level = ::Logger::WARN
#    end

#链接数据库
Mongoid.load!(File.join(File.dirname(__FILE__),"config/mongoid.yml"),ENV['RACK_ENV'])

#链接redis，并初始化search，和缓存的对象
redis_config = YAML.load_file("config/redis.yml")["production"]

$redis_search = Redis.new(:host => redis_config['host_search'],:port => redis_config['port_search'],:db => redis_config['select_search'],:driver => :hiredis)

$redis_users = Redis.new(:host => redis_config['host_users'],:port => redis_config['port_users'],:db => redis_config['select_users'],:driver => :hiredis)

$redis_topics = Redis.new(:host => redis_config['host_topics'],:port => redis_config['port_topics'],:db => redis_config['select_topics'],:driver => :hiredis)

$redis_asks = Redis.new(:host => redis_config['host_asks'],:port => redis_config['port_asks'],:db => redis_config['select_asks'],:driver => :hiredis)

Redis::Search.configure do |config|
  config.redis = $redis_search
  config.complete_max_length = 100
  config.pinyin_match = true
end

before do
  @current_client = Client.where(:uri=>params[:client_id])
  if @current_client.count==0
    halt 401,"#{request.ip} Unauthorized access."
  end
end

get '/' do
  @current_client.first.info+" in "+ENV['RACK_ENV']
end

error 404 do
  'Page not found.'
end

error 500 do
  'Sorry there was a nasty error - ' + env['sinatra.error'].message.to_s
end

%w{models helpers controllers}.each do |dir|
  Dir.glob(File.expand_path("../#{dir}", __FILE__) + '/**/*.rb').each do |file|
    require file
  end
end