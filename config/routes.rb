Streamcongress::Application.routes.draw do

  root :to => 'main#index'
  match 'settings' => 'main#settings', :as => :settings
  match 'auth' => 'sessions#new', :as => :auth
  match 'out' => 'sessions#destroy', :as => :out

  resource :session

end
