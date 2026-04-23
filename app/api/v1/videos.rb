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

        metadata = YoutubeOembedService.fetch(params[:youtube_url])
        error!({ error: "Could not fetch YouTube video info. Check the URL." }, 422) unless metadata

        video = current_user.videos.build(
          youtube_url: params[:youtube_url],
          youtube_id: YoutubeOembedService.extract_id(params[:youtube_url]),
          title: metadata[:title],
          description: metadata[:description]
        )

        if video.save
          VideoShareNotificationJob.perform_later(video.id)
          status :created
          present video, with: V1::Entities::Video
        else
          error!(video.errors.full_messages.join(", "), 422)
        end
      end
    end
  end
end
