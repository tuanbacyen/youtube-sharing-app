module V1
  module Entities
    class Video < Grape::Entity
      expose :id
      expose :youtube_url
      expose :youtube_id
      expose :title
      expose :description
      expose :shared_by do |video|
        video.user.email
      end
      expose :created_at
    end
  end
end
