module TelegramIntegration
  class ApiController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_enabled
    before_action :verify_api_token
    before_action :check_ip_whitelist

    # 用户绑定
    def bind_user
      telegram_user_id = params[:telegram_user_id]
      discourse_user_id = params[:discourse_user_id]

      PluginStore.set(PLUGIN_NAME, "binding_#{telegram_user_id}", discourse_user_id)
      PluginStore.set(PLUGIN_NAME, "binding_reverse_#{discourse_user_id}", telegram_user_id)

      render json: { success: true, message: "用户绑定成功" }
    end

    # 用户注册
    def register_user
      username = params[:username]
      email = params[:email]
      password = params[:password]
      telegram_user_id = params[:telegram_user_id]

      user = User.create!(username: username, email: email, password: password, active: true)
      PluginStore.set(PLUGIN_NAME, "binding_#{telegram_user_id}", user.id)

      render json: { success: true, message: "用户注册成功", user_id: user.id }
    end

    # 创建帖子
    def create_post
      title = params[:title]
      raw = params[:raw]
      category_id = params[:category_id]
      user = ensure_logged_in_user

      topic = TopicCreator.new(user, title: title, raw: raw, category_id: category_id).create
      render json: { success: true, topic_id: topic.id, message: "帖子创建成功" }
    end

    # 回复帖子
    def reply_post
      topic_id = params[:topic_id]
      raw = params[:raw]
      user = ensure_logged_in_user

      post = PostCreator.create!(user, topic_id: topic_id, raw: raw)
      render json: { success: true, post_id: post.id, message: "回复成功" }
    end

    # 获取分类
    def categories
      categories = Category.all.map { |c| { id: c.id, name: c.name } }
      render json: { success: true, categories: categories }
    end

    # 获取主题
    def topics
      category = Category.find(params[:id])
      topics = category.topics.visible.map { |t| { id: t.id, title: t.title } }
      render json: { success: true, topics: topics }
    end

    # 搜索
    def search
      term = params[:term]
      search_results = Search.execute(term)
      results = search_results.posts.map { |p| { id: p.id, topic_id: p.topic_id, excerpt: p.excerpt } }
      render json: { success: true, results: results }
    end

    # 点赞
    def like_post
      post_id = params[:post_id]
      user = ensure_logged_in_user

      PostActionCreator.create!(user, post_id, PostActionType.types[:like])
      render json: { success: true, message: "点赞成功" }
    end

    # Telegram Webhook
    def telegram_webhook
      telegram_data = JSON.parse(request.body.read)
      telegram_user_id = telegram_data.dig("message", "from", "id")
      message = telegram_data.dig("message", "text")

      discourse_user_id = PluginStore.get(PLUGIN_NAME, "binding_#{telegram_user_id}")
      if discourse_user_id
        send_telegram_message(telegram_user_id, "收到您的消息: #{message}")
      else
        send_telegram_message(telegram_user_id, "请先绑定您的账户。")
      end

      render json: { success: true }
    end

    private

    # 验证 API Token
    def verify_api_token
      token = request.headers["Authorization"]
      expected_token = SiteSetting.telegram_api_token
      raise Discourse::InvalidAccess.new unless ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
    end

    # 检查 IP 白名单
    def check_ip_whitelist
      ip_whitelist = SiteSetting.telegram_ip_whitelist.split(",").map(&:strip)
      client_ip = request.remote_ip
      raise Discourse::InvalidAccess.new unless ip_whitelist.include?(client_ip)
    end

    # 验证用户登录
    def ensure_logged_in_user
      user_id = params[:user_id]
      user = User.find_by(id: user_id)
      raise Discourse::InvalidAccess unless user

      user
    end

    # 向 Telegram 发送消息
    def send_telegram_message(chat_id, text)
      token = SiteSetting.telegram_bot_token
      uri = URI("https://api.telegram.org/bot#{token}/sendMessage")
      Net::HTTP.post_form(uri, { chat_id: chat_id, text: text })
    end

    # 确保插件已启用
    def ensure_enabled
      raise Discourse::InvalidAccess unless SiteSetting.telegram_integration_enabled
    end
  end
end
