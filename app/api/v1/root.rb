module V1
  class Root < Grape::API
    version "v1", using: :path

    helpers V1::Helpers::AuthHelpers
    mount V1::Auth
    mount V1::Videos
  end
end
