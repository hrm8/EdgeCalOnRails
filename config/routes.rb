Rails.application.routes.draw do
  get 'mass_event_creation/index'

  get 'mass_event_creation/help'

  get 'mass_event_creation/show'

  get 'free_time/create'

  get 'free_time/find'

  get 'free_time/show'

  get 'time_slot/new'

  get 'time_slot/index'

  get 'requests/index'

  get 'requests/new'

  get 'requests/show'

  get 'requests/edit'

  get 'index/show'

  get 'index/edit'

  get 'to_dos/index'

  get 'to_dos/edit'

  get 'to_dos/new'

  get 'subscription/index'

  get 'groups/index'

  get 'groups/show'

  get 'groups/new'
  
  get 'groups/new_modal'

  get 'groups/edit'

  get 'groups/delete'

  post 'events/create'

  post 'subscription/manage'
  
  get 'events/requests_modal' => 'events#requests_modal'
  
  get 'events/new_event_modal' => 'events#new_event_modal'
  
  get 'events/to_do_list_modal' => 'events#to_do_list_modal'
  
  get 'events/busy_events.json' => 'events#busy_events'
  
  get 'events/visible_events.json' => 'events#visible_events'
  
  get 'events/created_events.json' => 'events#created_events'
  
  get 'events/PUD_events.json' => 'events#PUD_events'
  
  get 'events/invited_events.json' => 'events#invited_events'
    
  # GET /events/1/get_subscribers
  get 'events/:id/get_subscribers' => 'events#get_subscribers'

  devise_for :users
  
  devise_scope :user do
    authenticated :user do
      root 'events#index', as: :authenticated_root
    end

    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
  
  resources :events do
    member do
      get :delete
    end
  end
  resources :groups

  mount Judge::Engine => '/judge'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

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

  match ':controller(/:action(/:id))', :via => [:get, :post, :patch, :delete]
end
