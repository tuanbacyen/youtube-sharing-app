class JwtDenylist < ApplicationRecord
  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true
end
