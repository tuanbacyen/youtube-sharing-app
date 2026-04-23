require 'rails_helper'

RSpec.describe JwtService do
  let(:payload) { { user_id: 1 } }

  describe '.encode' do
    it 'returns a JWT string' do
      expect(JwtService.encode(payload)).to be_a(String)
    end

    it 'embeds jti and exp into the token' do
      token = JwtService.encode(payload)
      decoded = JwtService.decode(token)
      expect(decoded['jti']).to be_present
      expect(decoded['exp']).to be_present
    end
  end

  describe '.decode' do
    it 'returns the payload for a valid token' do
      token = JwtService.encode(payload)
      expect(JwtService.decode(token)['user_id']).to eq(1)
    end

    it 'returns nil for an invalid token' do
      expect(JwtService.decode('invalid.token.here')).to be_nil
    end

    it 'returns nil for an expired token' do
      token = JwtService.encode(payload.merge(exp: 1.hour.ago.to_i))
      expect(JwtService.decode(token)).to be_nil
    end
  end
end
