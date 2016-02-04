Rails.application.routes.draw do


  resources :scientific_topics
  resources :workflows

  get 'static/welcome'
  get 'about' => 'static#about', as: 'about'

  post 'materials/check_exists' => 'materials#check_exists'
  post 'events/check_exists' => 'events#check_exists'
  post 'content_providers/check_exists' => 'content_providers#check_exists'

  devise_for :users
  get 'users/new' => 'users#new'
  get 'users/:id' => 'profiles#show'
  get 'profile/:id' => 'profiles#show', as: 'profile'
  patch 'profile/:id' => 'profiles#update'
  resources :profiles

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  root 'static#welcome'

  get 'static/welcome'

  resources :users

  resources :activities
  resources :nodes
  resources :events do
    resource :activities, :only => [:show]
  end
  resources :packages do
    resource :activities, :only => [:show]
    get 'manage' => 'packages#manage'
    post 'update_package_resources' => 'packages#update_package_resources'
=begin    post 'remove_resources' => 'packages#remove_resources'
=end
  end
  resources :workflows
  resources :content_providers do
    resource :activities, :only => [:show]
  end
  resources :materials do
    resource :activities, :only => [:show]
  end

  get 'search' => 'search#index'
=begin
  authenticate :user do
    resources :materials, only: [:new, :create, :edit, :update, :destroy]
  end
  resources :materials, only: [:index, :show]
=end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
