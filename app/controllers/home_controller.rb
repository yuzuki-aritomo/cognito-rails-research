class HomeController < ApplicationController
  def index
    render json: { message: 'Hello, World!!', user: @current_user }
  end
end
