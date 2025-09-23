Rails.application.routes.draw do
  namespace :v1 do
    resources :transactions do
      member do
        patch :flag
        patch :unflag
        patch :flag_type      # {flag_type, message?}
        patch :unflag_type    # {flag_type}
        patch :update_flag    # {flag_type, message}
        delete :destroy
      end
      collection do
        post :bulk_update
        post :bulk_flag
        post :bulk_unflag
        post :bulk_unflag_type  # {ids:[], flag_type}
        get  :flags             # returns flags with messages
        post :import_csv
        post :bulk_destroy
      end
    end
    resources :categories, only: %i[index show create update destroy]
    resources :rules, only: %i[index show create update destroy]
    resources :import_batches, only: [:show]
  end
end
