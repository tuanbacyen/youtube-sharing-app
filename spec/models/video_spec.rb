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

    it 'accepts YouTube Shorts URLs' do
      video = build(:video, youtube_url: 'https://www.youtube.com/shorts/dQw4w9WgXcQ')
      expect(video).to be_valid
    end

    describe 'youtube_id uniqueness' do
      it 'rejects duplicate youtube_id regardless of URL format' do
        create(:video, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', youtube_id: 'dQw4w9WgXcQ')
        duplicate = build(:video, youtube_url: 'https://youtu.be/dQw4w9WgXcQ', youtube_id: 'dQw4w9WgXcQ')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:youtube_id]).to include('has already been shared')
      end

      it 'allows updating a video without triggering uniqueness error' do
        video = create(:video, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', youtube_id: 'dQw4w9WgXcQ')
        video.title = 'Updated title'
        expect(video).to be_valid
      end
    end
  end

  describe '#set_youtube_id' do
    it 'extracts and sets youtube_id before validation' do
      video = build(:video, youtube_url: 'https://www.youtube.com/watch?v=abc123defgh', youtube_id: nil)
      video.valid?
      expect(video.youtube_id).to eq('abc123defgh')
    end
  end
end
