# coding: utf-8
get '/doing' do
  pagination_get_ready
  @logs = Log.only(Log::FIELDS).desc(:created_at)
  @ret = @logs.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end

get '/search' do
  pagination_get_ready
  the_limit = 1000
  case params[:type]
  when 'Topic'
    result = Redis::Search.query("Topic",params[:q].to_s.strip,:limit => the_limit,:sort_field=>'followers_count')
  when 'User'
    result = Redis::Search.complete("User",params[:q].to_s.strip,:limit => the_limit,:sort_field=>'followers_count')
  when 'Ask'
    result = Redis::Search.query("Ask",params[:q].to_s.strip,:limit => the_limit,:sort_field=>'answers_count')
  else
    result=[]
  end
  @asks = result
  @ret = @asks[(@page-1)*@per_page,@per_page].to_a
  render_this!
end