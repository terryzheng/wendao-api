# coding: utf-8
class Ask
  include Mongoid::Document

  field :title
  field :user_id
  field :answers_count
  field :spams_count
  field :deleted
  scope :unanswered, where(:answers_count => 0)
  scope :normal, where(:spams_count.lt => 8)
  scope :nondeleted, where(:deleted.nin=>[1,3])
  
  FIELDS=[:title,:user_id,:answers_count]
  
  def as_json(opts={})
    if opts[:wendao_show]
      super(opts)
    else
      user = $redis_users.hgetall(self.user_id)
      {id:self.id,title:self.title,user:[user["slug"],user["name"]],answers_count:self.answers_count}
    end
  end
end