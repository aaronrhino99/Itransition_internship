class UsersController < ApplicationController
  DONE = { "block" => "blocked", "unblock" => "unblocked", "delete" => "deleted" }.freeze

  def index
    @users = User.order(Arel.sql("current_sign_in_at DESC NULLS LAST"))
  end

  def bulk
    ids = Array(params[:user_ids])
    return redirect_to(root_path, alert: "Select at least one user.", status: :see_other) if ids.empty?

    scope = User.where(id: ids)
    count =
      case params[:op]
      when "block"   then scope.update_all(status: "blocked", updated_at: Time.current)
      when "unblock" then scope.update_all(status: "active", updated_at: Time.current)
      when "delete"  then scope.delete_all
      else return redirect_to(root_path, alert: "Unknown action.", status: :see_other)
      end

    redirect_to root_path, notice: "#{count} user(s) #{DONE[params[:op]]}.", status: :see_other
  end
end