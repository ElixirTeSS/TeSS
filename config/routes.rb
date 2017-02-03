Rails.application.routes.draw do

  concern :collaboratable do
    resources :collaborations, only: [:create, :destroy, :index, :show]
  end

  resources :scientific_topics
  resources :workflows

  #get 'static/home'
  get 'about' => 'static#about', as: 'about'

  post 'materials/check_exists' => 'materials#check_exists'
  post 'events/check_exists' => 'events#check_exists'
  post 'content_providers/check_exists' => 'content_providers#check_exists'

  #devise_for :users
  # Use custom registrations controller that subclasses devise's
  devise_for :users, :controllers => {
      :registrations => 'tess_devise/registrations',
      :omniauth_callbacks => 'callbacks'
  }
  #Redirect to users index page after devise user account update
  # as :user do
  #   get 'users', :to => 'users#index', :as => :user_root
  # end

  patch 'users/:id/change_token' => 'users#change_token', as: 'change_token'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  root 'static#home'

  get 'static/home'

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
  resources :workflows, concerns: :collaboratable do
    member do
      get 'fork'
    end
  end

  resources :content_providers do
    resource :activities, :only => [:show]
  end

  resources :materials do
    resource :activities, :only => [:show]
  end

  post 'materials/:id/update_packages' => 'materials#update_packages'
  post 'events/:id/update_packages' => 'events#update_packages'

  get 'search' => 'search#index'


  # error pages
  %w( 404 422 500 503 ).each do |code|
    get code, :to => "application#handle_error", :status_code => code
  end

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
