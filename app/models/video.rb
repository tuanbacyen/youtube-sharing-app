class Video < ApplicationRecord
  belongs_to :user

  validates :youtube_url, presence: true
  validate :youtube_url_format

  before_create :set_youtube_id

  private

  def youtube_url_format
    return if YoutubeOembedService.extract_id(youtube_url.to_s)
    errors.add(:youtube_url, 'is not a valid YouTube URL')
  end

  def set_youtube_id
    self.youtube_id = YoutubeOembedService.extract_id(youtube_url)
  end
end
