# plugin.rb
# frozen_string_literal: true

# 插件基本信息
# name: discourse-lottery
# about: 在帖子底部添加抽奖按钮，楼主/管理员/版主可随机抽奖
# version: 0.1
# authors: 你的名字
# url: https://github.com/zaixiangjian/discourse-lottery

enabled_site_setting :lottery_enabled

after_initialize do
  # 添加路由
  Discourse::Application.routes.append do
    post '/lottery/draw' => 'lottery#draw'
    get '/lottery/winners/:topic_id' => 'lottery#winners'
  end

  # 控制器
  class ::LotteryController < ::ApplicationController
    requires_plugin 'discourse-lottery'
    before_action :ensure_logged_in

    def draw
      topic_id = params.require(:topic_id).to_i
      draw_count = params[:count].to_i.clamp(1, 10) # 限制抽奖人数 1-10

      topic = Topic.find_by(id: topic_id)
      return render_json_error("找不到主题") if topic.nil?

      # 权限校验：只有楼主、管理员、版主能抽奖
      unless current_user.id == topic.user_id || current_user.admin? || current_user.moderator?
        return render_json_error("没有权限抽奖")
      end

      # 获取评论者，排除楼主和重复用户
      post_user_ids = Post.where(topic_id: topic_id).where.not(user_id: topic.user_id).pluck(:user_id).uniq

      if post_user_ids.empty?
        return render_json_error("没有符合抽奖资格的用户")
      end

      winners = post_user_ids.sample(draw_count)

      # 保存中奖数据到 PluginStore
      PluginStore.set('discourse-lottery', "winners_#{topic_id}", {
        winners: winners,
        drawn_at: Time.now.utc
      })

winner_users = User.where(id: winners).pluck(:username)
render json: success_json.merge(winners: winner_users)
    end

    def winners
      topic_id = params.require(:topic_id).to_i
      data = PluginStore.get('discourse-lottery', "winners_#{topic_id}")
      render json: data || {}
    end
  end

  # 给 Topic 序列化器增加抽奖信息
  add_to_serializer(:topic_view, :lottery_winners) do
    data = PluginStore.get('discourse-lottery', "winners_#{object.topic.id}")
    data ? data[:winners] : []
  end

  add_to_serializer(:topic_view, :lottery_drawn_at) do
    data = PluginStore.get('discourse-lottery', "winners_#{object.topic.id}")
    data ? data[:drawn_at] : nil
  end
end
