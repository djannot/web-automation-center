Clouds::Application.routes.draw do
  resources :demos
  resources :users
  resources :sessions
  resources :clouds
  resources :platforms

  root :to => 'clouds#index'

  get "log_out" => "sessions#destroy", :as => "log_out"
  get "log_in" => "sessions#new", :as => "log_in"
  get "sign_up" => "users#new", :as => "sign_up"

  get 'cloud/client_side_upload_response/:cloud_id' => 'cloud#client_side_upload_response'
  get 'platform/show_subtenant_details/:platform_id/:subtenant_name' => 'platform#show_subtenant_details'
  get 'platform/show_uid_metrics/:platform_id/:subtenant_name/:uid' => 'platform#show_uid_metrics'
  get 'cloud/:action/:cloud_id' => 'cloud#:action'
  get 'platform/:action/:platform_id' => 'platform#:action'
  get 'demos/:action/:id' => 'demos#:action'
  get 'demo/:action/:id' => 'demo#:action'
  get 'backup/restore/:email/:key/:password' => 'backup#restore', :constraints => { :email => /[^\/]+/ }
  get 'backup/import/Favorites/:api_type/:api/:email/:name' => 'backup#restore', :constraints => { :email => /[^\/]+/ }
  get 'backup/delete/Favorites/:api_type/:api/:email/:name' => 'backup#delete_cloud_data', :constraints => { :email => /[^\/]+/ }
  get 'backup/import/Demos/:email/:name' => 'backup#restore', :constraints => { :email => /[^\/]+/ }
  get 'backup/delete/Demos/:email/:name' => 'backup#delete_cloud_data', :constraints => { :email => /[^\/]+/ }
  get 'backup/delete_cloud_data/:email/:key' => 'backup#delete_cloud_data', :constraints => { :email => /[^\/]+/ }
  get 'backup/:action/favorite/:favorites/:favorite_id' => 'backup#:action'
  get 'backup/:action/favorite/:favorites/:favorite_id/:backup_action' => 'backup#:action'
  get 'backup/:action/demo/:demos/:favorites/:demo_id' => 'backup#:action'
  get 'backup/:action/demo/:demos/:favorites/:demo_id/:backup_action' => 'backup#:action'
  get 'backup/:action' => 'backup#:action'
  post 'platform/:action/:platform_id' => 'platform#:action'
  post 'cloud/:action/:cloud_id' => 'cloud#:action'
  post 'platform/:action/:platform_id/:task_id' => 'platform#:action'
  post 'cloud/:action/:cloud_id/:task_id' => 'cloud#:action'
  post 'demos/:action/:id' => 'demos#:action'
  post 'demo/:action/:id' => 'demo#:action'
  post 'backup/:action' => 'backup#:action'
  get 'clouds/:action/:id' => 'clouds#:action'
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
