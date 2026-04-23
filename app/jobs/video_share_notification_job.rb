class VideoShareNotificationJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find_by(id: video_id)
    return unless video

    # TODO: broadcast notification to ActionCable subscribers
  end
end
