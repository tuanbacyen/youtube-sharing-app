class VideoShareNotificationJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.includes(:user).find(video_id)
    ActionCable.server.broadcast(
      'notifications',
      {
        type: 'new_video',
        title: video.title,
        shared_by: video.user.email
      }
    )
  end
end
