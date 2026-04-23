class JwtService
  ALGORITHM = "HS256"

  def self.encode(payload)
    payload = payload.merge(
      jti: SecureRandom.uuid,
      exp: 24.hours.from_now.to_i
    )
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret, true, algorithm: ALGORITHM)
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.secret
    ENV.fetch("JWT_SECRET", Rails.application.credentials.secret_key_base)
  end
end
