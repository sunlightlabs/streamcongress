Streamcongress::Application.routes.draw do

  root :to => "main#index"
  match 'auth' => 'sessions#new', :as => :auth
  match 'out' => 'sessions#destroy', :as => :out
  
  resource :session
  
end
