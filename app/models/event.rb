class Event < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  #Make sure there's link and title

end
