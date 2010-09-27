Streamcongress::Application.routes.draw do

  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  root :to => "main#index"
  
end
