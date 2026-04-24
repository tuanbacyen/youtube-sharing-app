class Video < ApplicationRecord
  belongs_to :user

  validates :youtube_url, presence: true
  validates :youtube_id, uniqueness: { message: "has already been shared" }
  validate :youtube_url_format

  before_validation :set_youtube_metadata
  after_create_commit -> { VideoShareNotificationJob.perform_later(id) }

  private

  def youtube_url_format
    return if YoutubeOembedService.extract_id(youtube_url.to_s)
    errors.add(:youtube_url, "is not a valid YouTube URL")
  end

  def set_youtube_metadata
    self.youtube_id = YoutubeOembedService.extract_id(youtube_url.to_s)
    return if youtube_id.nil? || (title.present? && description.present?)
    metadata = YoutubeOembedService.fetch(youtube_url.to_s)
    self.title       = metadata[:title]       if title.blank?
    self.description = metadata[:description] if description.blank?
  end
end
