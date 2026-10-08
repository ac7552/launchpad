class ProjectVersion < ApplicationRecord
  belongs_to :project

  validates :author, inclusion: { in: Project::AUTHORS }
end
