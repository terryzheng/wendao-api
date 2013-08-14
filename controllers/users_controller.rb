# coding: utf-8
get '/users/:id' do
  content_type :json
  slug=params[:id]
  if !api_super_client? and api_current_user_slug!=slug
    halt [401,"Unauthorized access."]
  end
  
  u=User.nondeleted.only(User::FIELDS).where(:slug=>slug).first
  u ||= User.nondeleted.only(User::FIELDS).where(:email=>params[:email]).first if !params[:email].blank?
  u ||= User.nondeleted.only(User::FIELDS).where(:_id=>slug).first
  u.to_json
end

get '/users' do
  content_type :json
  pagination_get_ready
  if params[:experts].blank? and params[:elites].blank? and params[:current_user].blank?
    halt [401,"it is not allowed to get all users"]
  end
  
  if !params[:current_user].blank?
    if api_current_user_slug.blank?
      halt [401,"Unauthorized access."]
    end
    halt User.nondeleted.only(User::FIELDS).where(:slug=>api_current_user_slug).first.to_json
  elsif !params[:experts].blank?
    @users = User.nondeleted.only(User::FIELDS)
    @users = @users.where(:expert_type=>User::EXPERT_USER)
  elsif !params[:elites].blank?
    @users = User.nondeleted.only(User::FIELDS)
    @users = @users.where(:expert_type=>User::ELITE_USER)
  end
  @ret = @users.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end

get '/users/:id/asked' do
  content_type :json
  get_user
  pagination_get_ready
  @asks = Ask.nondeleted.normal.only(Ask::FIELDS).where(:user_id=>@user.id).desc(:created_at)
  @ret = @asks.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end

get '/users/:id/asked_to' do
  content_type :json
  get_user("ask_to_me_ids")
  pagination_get_ready
  @asks = Ask.nondeleted.normal.only(Ask::FIELDS).any_in(:_id=>@user.ask_to_me_ids).desc(:created_at)
  @ret = @asks.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end

get '/users/:id/answered' do
  content_type :json
  get_user
  pagination_get_ready
  @answers = Answer.nondeleted.only(Answer::FIELDS).where(:user_id=>@user.id)
  @ret = @answers.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end
  
get '/users/:id/comments' do
  content_type :json
  get_user
  pagination_get_ready
  @comments = Comment.nondeleted.only(Comment::FIELDS).where(:user_id=>@user.id)
  @ret = @comments.skip((@page-1)*@per_page).limit(@per_page)
  render_this!
end

get '/users/:id/following' do
  content_type :json
  slug=params[:id]
  user=User.nondeleted.only(:following_ids,:followed_ask_ids,:followed_topic_ids).where(:slug=>slug).first
  {users:user.following_ids,asks:user.followed_ask_ids,topics:user.followed_topic_ids}.to_json
end

get '/users/:id/followed' do
  content_type :json
  slug=params[:id]
  user=User.nondeleted.only(:follower_ids).where(:slug=>slug).first
  user.follower_ids.to_json
end
  
get '/users/:id/suggestions' do
  content_type :json
  slug=params[:id]
  if !api_super_client? and api_current_user_slug!=slug
    halt [401,"Unauthorized access."]
  end

  user=User.nondeleted.only(:followed_topic_ids,:following_ids).where(:slug=>slug).first
  if user and !(user.followed_topic_ids.blank? and user.following_ids.blank?)
    elim = (user.expert_type==User::EXPERT_USER or user.expert_type==User::ELITE_USER) ? 3 : 2
    ulim = (user.expert_type==User::EXPERT_USER or user.expert_type==User::ELITE_USER) ? 0 : 1
    tlim = 2
    usi = UserSuggestItem.where(:user_id=>user.id).first
    e = usi.suggested_experts
    u = usi.suggested_users
    t = usi.suggested_topics
    @suggested_experts =  User.nondeleted.only(User::FIELDS).any_in(:_id=>e.sort_by{rand}[0,elim]).not_in(:_id=>user.following_ids)
    @suggested_users = User.nondeleted.only(User::FIELDS).any_in(:_id=>u.sort_by{rand}[0,ulim]).not_in(:_id=>user.following_ids)
    @suggested_topics = Topic.nondeleted.only(Topic::FIELDS).any_in(:name=>t.sort_by{rand}[0,tlim])
  end
  {experts:@suggested_experts,users:@suggested_users,topics:@suggested_topics}.to_json
end