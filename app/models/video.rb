class Video < ApplicationRecord
  belongs_to :user

  validates :youtube_url, presence: true
  validate :youtube_url_format
  validate :youtube_id_unique

  before_validation :set_youtube_id

  private

  def youtube_url_format
    return if YoutubeOembedService.extract_id(youtube_url.to_s)
    errors.add(:youtube_url, "is not a valid YouTube URL")
  end

  def set_youtube_id
    self.youtube_id = YoutubeOembedService.extract_id(youtube_url.to_s)
  end

  def youtube_id_unique
    return unless youtube_id
    return unless Video.where(youtube_id: youtube_id).where.not(id: id).exists?
    errors.add(:youtube_url, "has already been shared")
  end
end
