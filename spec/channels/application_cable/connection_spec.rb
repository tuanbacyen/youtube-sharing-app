require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:jti) { SecureRandom.uuid }
  let(:valid_token) do
    JWT.encode(
      { user_id: user.id, jti: jti, exp: 24.hours.from_now.to_i },
      JwtService.secret,
      JwtService::ALGORITHM
    )
  end

  context 'with a valid token and live user' do
    it 'accepts the connection and sets current_user' do
      connect "/cable?token=#{valid_token}"
      expect(connection.current_user).to eq(user)
    end
  end

  context 'with no token' do
    it 'rejects the connection' do
      expect { connect '/cable' }.to have_rejected_connection
    end
  end

  context 'with an invalid/expired token (JwtService.decode returns nil)' do
    it 'rejects the connection' do
      allow(JwtService).to receive(:decode).and_return(nil)
      expect { connect '/cable?token=bad_token' }.to have_rejected_connection
    end
  end

  context 'with a revoked token (jti present in JwtDenylist)' do
    before { JwtDenylist.create!(jti: jti, exp: 24.hours.from_now) }

    it 'rejects the connection' do
      expect { connect "/cable?token=#{valid_token}" }.to have_rejected_connection
    end
  end

  context 'with a valid token but user not found' do
    it 'rejects the connection' do
      token = JWT.encode(
        { user_id: 0, jti: SecureRandom.uuid, exp: 24.hours.from_now.to_i },
        JwtService.secret,
        JwtService::ALGORITHM
      )
      expect { connect "/cable?token=#{token}" }.to have_rejected_connection
    end
  end
end
