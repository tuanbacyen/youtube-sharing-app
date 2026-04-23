class ApiRoot < Grape::API
  # format :json
  # prefix :api

  include BaseApiRootModule

  rescue_from ActiveRecord::RecordNotFound do
    error!({ error: "Not found" }, 404)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    error!({ error: e.message }, 400)
  end

  mount V1::Root
end
