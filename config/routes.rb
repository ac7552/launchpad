Rails.application.routes.draw do
  resource :session
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
  get "curriculum" => "curriculum#show"
  get "privacy" => "privacy#show"

  # Parents reach these from the link in their email; there's no parent login.
  scope "parent/:token", controller: :parents, as: :parent do
    get "/", action: :show, as: :consent
    post "consent", action: :consent, as: :submit
    post "decline", action: :decline, as: :decline
    post "ai", action: :ai, as: :ai
    get "export", action: :export, as: :export
    delete "/", action: :destroy, as: :erase
  end

  # Student side
  resources :projects, except: :edit do
    member { post :back_to_blocks }
    resources :ai_interactions, only: :create
    resources :help_sessions, only: :create
  end
  resources :help_sessions, only: [] do
    member do
      post :respond
      post :abandon
    end
  end
  resources :ai_interactions, only: [] do
    member do
      post :accept
      post :reject
    end
  end

  # Teacher side
  namespace :teach do
    resources :classrooms, only: %i[index show new create] do
      resource :ai_policy, only: :update
      resources :students, only: %i[new create]
    end
    resources :students, only: :show do
      resources :skill_checks, only: %i[create destroy]
      resource :consent, only: :create do
        post :verify
      end
      delete :erase, on: :member
    end
    resources :consents, only: :index
    resources :projects, only: :show
    resources :reviews, only: :index do
      member do
        post :approve
        post :deny
        post :dismiss
      end
    end
    resources :help_sessions, only: [] do
      member { post :resolve }
    end
  end
end
