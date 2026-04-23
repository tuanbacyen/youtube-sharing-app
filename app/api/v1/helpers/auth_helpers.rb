module V1
  module Helpers
    module AuthHelpers
      def authenticate!
        error!(error: "Unauthorized", status: 401) unless current_user
      end

      def current_user
        return @current_user if defined?(@current_user)
        token = headers["Authorization"]&.split(" ")&.last
        return @current_user = nil unless token

        payload = JwtService.decode(token)
        return @current_user = nil unless payload
        return @current_user = nil if JwtDenylist.exists?(jti: payload["jti"])

        @current_user = User.find_by(id: payload["user_id"])
      end

      def current_token_payload
        token = headers["Authorization"]&.split(" ")&.last
        JwtService.decode(token)
      end
    end
  end
end
