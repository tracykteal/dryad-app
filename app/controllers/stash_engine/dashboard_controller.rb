require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login

    def show
      #@resources = Resource.where(user_id: current_user.id)
      #@titles = metadata_engine::Title.where(resource_id: @resources.pluck(:id))
      #byebug
    end
  end
end
