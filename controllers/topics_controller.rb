# coding: utf-8
get '/topics' do
  pagination_get_ready
  if !params[:newbie].blank?
    @topics = TopicCache.only(TopicCache::FIELDS)
  else
    @topics = Topic.only(Topic::FIELDS).nondeleted
    @topics = @topics.where(:name=>/#{params[:q]}/) if params[:q]
    @topics = @topics.where(:tags => params[:tag]) if params[:tag]
    @topics = @topics.desc(params[:sort]) if params[:sort]
    @topics = @topics.desc("created_at")
  end
  @ret = @topics.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end
  
get '/topics/:name/suggest_topics' do
  content_type :json
  get_topic
  @related_topics = TopicSuggestTopic.only(:topics).where(:topic_id=>@topic_id).first
  if !@related_topics.blank?
    @related_topics.topics.to_json
  else
    "[]"
  end
end
  
get '/topics/:name/suggest_experts' do
  content_type :json
  get_topic
  @related_topics = TopicSuggestExpert.only(:expert_ids).where(:topic_id=>@topic_id).first
  if !@related_topics.blank?
    @related_topics.expert_ids.to_json
  else
    "[]"
  end
end
