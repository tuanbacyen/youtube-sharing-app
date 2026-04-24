module V1
  class Videos < Grape::API
    resource :videos do
      desc "List all videos, newest first"
      get do
        videos = Video.includes(:user).order(created_at: :desc)
        present videos, with: V1::Entities::Video
      end

      desc "Share a YouTube video"
      params do
        requires :youtube_url, type: String
      end
      post do
        authenticate!

        video = current_user.videos.build(youtube_url: params[:youtube_url])

        if video.save
          status :created
          present video, with: V1::Entities::Video
        else
          error!(video.errors.full_messages.join(", "), 422)
        end
      end
    end
  end
end
