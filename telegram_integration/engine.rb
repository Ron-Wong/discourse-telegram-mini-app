module TelegramIntegration
  class Engine < ::Rails::Engine
    isolate_namespace TelegramIntegration

    post "/bind_user" => "api#bind_user"
    post "/register_user" => "api#register_user"
    post "/post" => "api#create_post"
    post "/reply" => "api#reply_post"
    get "/categories" => "api#categories"
    get "/topics/:id" => "api#topics"
    get "/search" => "api#search"
    post "/like" => "api#like_post"
    post "/webhook" => "api#webhook"
    post "/telegram_webhook" => "api#telegram_webhook"
  end
end
