class Download
  def self.total
    Repositories.descendants.sum{|pm| pm.project_names.length}
  end

  def self.keys
    Repositories.descendants.flat_map(&:keys).map(&:to_s).sort.uniq
  end
end
