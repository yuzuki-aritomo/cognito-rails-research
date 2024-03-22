class HomeController < ApplicationController
  def index
    render json: { user: @current_user, groups: @groups }
  end
end
