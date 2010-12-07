Streamcongress::Application.routes.draw do

  root :to => 'main#index'
  match 'settings' => 'main#settings', :as => :settings
  match 'chrome' => 'main#chrome', :as => :chrome

  match 'auth' => 'sessions#new', :as => :auth
  match 'out' => 'sessions#destroy', :as => :out

  match 's/:slug' => 'main#publisher', :as => :publisher
  match 'a/:id' => 'main#activity', :as => :activity
  match 'a/:id/comment' => 'main#comment', :as => :comment
  
  resource :session

end
