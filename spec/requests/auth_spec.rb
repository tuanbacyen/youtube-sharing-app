require 'rails_helper'

RSpec.describe 'Auth API', type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) { { email: "test@example.com", password: "password123" } }

    context 'with valid params' do
      it 'creates a user and returns a JWT token' do
        post '/api/v1/auth/register', params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body['token']).to be_present
        expect(body['email']).to eq('test@example.com')
      end
    end

    context 'with duplicate email' do
      before { create(:user, email: 'test@example.com') }

      it 'returns 422' do
        post '/api/v1/auth/register', params: valid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with missing password' do
      it 'returns 400' do
        post '/api/v1/auth/register', params: { email: 'test@example.com' }, as: :json
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'POST /api/v1/auth/login' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns a JWT token and email' do
        post '/api/v1/auth/login', params: { email: 'test@example.com', password: 'password123' }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['token']).to be_present
        expect(body['email']).to eq('test@example.com')
      end
    end

    context 'with wrong password' do
      it 'returns 401' do
        post '/api/v1/auth/login', params: { email: 'test@example.com', password: 'wrong' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with unknown email' do
      it 'returns 401' do
        post '/api/v1/auth/login', params: { email: 'nobody@example.com', password: 'password123' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/auth/logout' do
    let!(:user) { create(:user) }
    let(:token) { JwtService.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    it 'denylists the token and returns 200' do
      delete '/api/v1/auth/logout', headers: auth_headers, as: :json
      expect(response).to have_http_status(:ok)
      payload = JwtService.decode(token)
      expect(JwtDenylist.exists?(jti: payload['jti'])).to be true
    end

    it 'returns 401 without Authorization header' do
      delete '/api/v1/auth/logout', as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
