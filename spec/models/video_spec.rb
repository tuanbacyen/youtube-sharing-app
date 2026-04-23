require 'rails_helper'

RSpec.describe Video, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:youtube_url) }

    it 'rejects non-YouTube URLs' do
      video = build(:video, youtube_url: 'https://vimeo.com/123')
      expect(video).not_to be_valid
      expect(video.errors[:youtube_url]).to include('is not a valid YouTube URL')
    end

    it 'accepts standard youtube.com URLs' do
      video = build(:video, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
      expect(video).to be_valid
    end

    it 'accepts youtu.be short URLs' do
      video = build(:video, youtube_url: 'https://youtu.be/dQw4w9WgXcQ')
      expect(video).to be_valid
    end
  end
end
