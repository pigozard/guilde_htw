class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to root_path, notice: "✅ Profil mis à jour !"
    else
      render :edit, alert: "Erreur lors de la mise à jour"
    end
  end

  private

  def user_params
    params.require(:user).permit(:nickname)
  end
end
