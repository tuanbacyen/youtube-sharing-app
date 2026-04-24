class User < ApplicationRecord
  has_secure_password
  has_many :videos, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, on: :create

  before_validation { self.email = email.downcase.strip if email.present? }
end
