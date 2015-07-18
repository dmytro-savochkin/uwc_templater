Uwctemplate::Application.routes.draw do
  root :to => 'welcome#index'
  match '*path' => 'welcome#index'
end
