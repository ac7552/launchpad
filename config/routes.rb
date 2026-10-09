Rails.application.routes.draw do
  resource :session
  get "up" => "rails/health#show", as: :rails_health_check

  # The world is home: an illustrated place you drag across, where every spot is a link.
  root "world#show"
  get "path" => "home#show", as: :path
  get "curriculum" => "curriculum#show"
  get "privacy" => "privacy#show"

  # Messages: one shared conversation per student (student, parents, teachers).
  get "messages" => "messages#index", as: :messages
  get "messages/:student_id" => "messages#show", as: :message_thread
  post "messages/:student_id" => "messages#create"

  # Parent portal (parents sign in with their email) and accepting a parent invite.
  get "family" => "family#show", as: :family
  get "family/:student_id" => "family#child", as: :family_child
  get "family/:student_id/projects/:id" => "family#project", as: :family_project
  get "join/:token" => "joins#show", as: :join
  post "join/:token" => "joins#create"

  # Permission links from the consent email (no login needed).
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
    member do
      post :back_to_blocks
      post :turn_in
    end
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
    resources :students, only: %i[index show update] do
      collection { post :bulk_tier }
      resources :skill_checks, only: %i[create destroy]
      resources :guardianships, only: :create
      resource :consent, only: :create do
        post :verify
      end
      delete :erase, on: :member
    end
    resources :consents, only: :index
    resources :grading, only: :index
    resources :project_reviews, only: :update
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
