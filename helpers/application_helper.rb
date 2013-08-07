# coding: utf-8
helpers do
  def get_ask
    if !$redis_asks.exists(params[:id])
      halt [{"error"=>"Ask not found."}.to_json]
    end
  end
  
  def get_topic
    @topic_id = $redis_topics.hget(params[:name],:id)
    if @topic_id.blank?
      halt [{"error"=>"Topic not found."}.to_json]
    end
  end
  
  def get_user
    @user=User.nondeleted.only(:_id).where(:slug=>params[:id]).first
    if @user.blank?
      halt [{"error"=>"User not found."}.to_json]
    end
  end
  
  def api_super_client?
    request.ip.starts_with?('192.168') or request.ip.starts_with?('172.30') or request.ip=='127.0.0.1'
  end

  def api_current_user_slug
    $redis_users.hget(@current_client.first.user_id,:slug)
  end

  def render_this!
    content_type :json
    {"size"=>@ret.to_a.count,"result"=>@ret}.to_json
  end
  
  def pagination_get_ready
    @page = (params[:page].to_i>0)? params[:page].to_i : 1
    @per_page = (params[:per_page].to_i>0)? ((params[:per_page].to_i>100)? 100 : params[:per_page].to_i) : 20
  end
end