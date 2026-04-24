module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      return reject_unauthorized_connection unless token

      payload = JwtService.decode(token)
      return reject_unauthorized_connection unless payload
      return reject_unauthorized_connection if JwtDenylist.exists?(jti: payload["jti"])

      User.find_by(id: payload["user_id"]) || reject_unauthorized_connection
    end
  end
end
