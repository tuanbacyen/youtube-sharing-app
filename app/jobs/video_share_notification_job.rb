class VideoShareNotificationJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(video_id)
    video = Video.includes(:user).find(video_id)
    ActionCable.server.broadcast(
      'notifications',
      {
        type:        'new_video',
        id:          video.id,
        title:       video.title,
        description: video.description,
        youtube_id:  video.youtube_id,
        youtube_url: video.youtube_url,
        shared_by:   video.user&.email
      }
    )
  end
end
