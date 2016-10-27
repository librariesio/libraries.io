task counts: :environment do
  counts = {}
  averages = {}
  Manifest.includes(:repository_dependencies).where(filepath: 'npm-shrinkwrap.json').find_each do |manifest|
    next if manifest.filepath.match(/\//)
    counts[manifest.filepath] ||= []
    counts[manifest.filepath] << manifest.repository_dependencies.length
  end

  counts.each do |k,v|
    averages[k] = v.instance_eval { reduce(:+) / size.to_f }
  end
  pp averages
end

# {"META.json"=>14.549211759693225, "META.yml"=>5.202832574607992}
# {"package.json"=>10.973721162602589, "npm-shrinkwrap.json"=>573.2219876338411, "yarn.lock"=>474.5843023255814}
# {"Gemfile"=>9.586365548257676, "Gemfile.lock"=>50.590976576755914
# {"bower.json"=>4.475359275000414}
# {"composer.json"=>4.666775216385294, "composer.lock"=>0.0}


# Researching average number of dependencies per filetype on GitHub:
#
# Gemfile: 10
# package.json: 11
# Gemfile.lock: 51
# npm-shrinkwrap.json: 160
