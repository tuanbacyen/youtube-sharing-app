require 'rails_helper'

RSpec.describe 'Videos API', type: :request do
  let!(:user) { create(:user) }
  let(:token) { JwtService.encode(user_id: user.id) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/videos' do
    let!(:videos) { create_list(:video, 3, user: user) }

    it 'returns all videos newest first without authentication' do
      get '/api/v1/videos', as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(3)
      expect(body.first['id']).to eq(videos.last.id)
    end

    it 'includes shared_by email in each video' do
      get '/api/v1/videos', as: :json
      body = JSON.parse(response.body)
      expect(body.first['shared_by']).to eq(user.email)
    end
  end

  describe 'POST /api/v1/videos' do
    let(:youtube_url) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }

    before do
      allow(YoutubeOembedService).to receive(:fetch).and_return(
        { title: 'Rick Astley', description: 'Rick Astley Channel' }
      )
    end

    context 'when authenticated' do
      it 'creates a video and enqueues VideoShareNotificationJob' do
        expect {
          post '/api/v1/videos',
               params: { youtube_url: youtube_url },
               headers: auth_headers,
               as: :json
        }.to change(Video, :count).by(1)
           .and have_enqueued_job(VideoShareNotificationJob)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body['title']).to eq('Rick Astley')
        expect(body['youtube_id']).to eq('dQw4w9WgXcQ')
        expect(body['shared_by']).to eq(user.email)
      end

      it 'returns 422 when oEmbed cannot fetch the video' do
        allow(YoutubeOembedService).to receive(:fetch).and_return(nil)
        post '/api/v1/videos',
             params: { youtube_url: 'https://not-youtube.com' },
             headers: auth_headers,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        post '/api/v1/videos', params: { youtube_url: youtube_url }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
