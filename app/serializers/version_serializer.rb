class VersionSerializer
  include FastJsonapi::ObjectSerializer
  attributes :number, :published_at

  belongs_to :project
end
