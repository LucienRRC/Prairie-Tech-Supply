class SitePagesController < ApplicationController
  def show
    @site_page = SitePage.find_by!(slug: params[:slug])
  end
end
