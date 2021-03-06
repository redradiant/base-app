Crimson::Application.routes.draw do

  begin
    devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  rescue Exception => e
    raise(e) unless Rails.env == "development"
  end

  get "pages/index"

  match "/admin" => "admin/base#index", :as => "admin"

  namespace "admin" do

    resources :users

  end

  root :to => "pages#index"

end
