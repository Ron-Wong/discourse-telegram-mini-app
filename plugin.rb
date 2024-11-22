# frozen_string_literal: true

PLUGIN_NAME ||= "discourse-telegram-mini-app"

enabled_site_setting :telegram_integration_enabled

after_initialize do
  module ::TelegramIntegration
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace TelegramIntegration
    end
  end

  TelegramIntegration::Engine.routes.draw do
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

  Discourse::Application.routes.append do
    mount ::TelegramIntegration::Engine, at: "/telegram"
  end
end
