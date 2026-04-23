class User < ApplicationRecord
  has_secure_password
  has_many :videos, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, on: :create

  before_save { self.email = email.downcase }
end
