module V1
  class Auth < Grape::API
    resource :auth do
      desc "Register a new user"
      params do
        requires :email, type: String
        requires :password, type: String
      end
      post :register do
        user = User.new(email: params[:email], password: params[:password])
        if user.save
          token = JwtService.encode(user_id: user.id)
          status :created
          { token: token, email: user.email }
        else
          error!(user.errors.full_messages.join(', '), 422)
        end
      end

      desc "Login"
      params do
        requires :email, type: String
        requires :password, type: String
      end
      post :login do
        user = User.find_by(email: params[:email].to_s.downcase)
        if user&.authenticate(params[:password])
          token = JwtService.encode(user_id: user.id)
          status :ok
          { token: token, email: user.email }
        else
          error!({ error: "Invalid email or password" }, 401)
        end
      end

      desc "Logout — invalidates the current JWT"
      delete :logout do
        authenticate!
        payload = current_token_payload
        JwtDenylist.create!(jti: payload["jti"], exp: Time.at(payload["exp"]))
        status :ok
        { message: "Logged out successfully" }
      end
    end
  end
end
