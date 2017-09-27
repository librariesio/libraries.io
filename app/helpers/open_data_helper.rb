module OpenDataHelper
  def open_data_releases
    {
      '1.0.0' => {
        date: 'June 06, 2107',
        files: [
          {
            filename: 'projects-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
          {
            filename: 'versions-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
          {
            filename: 'dependencies-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
          {
            filename: 'repositories-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
          {
            filename: 'tags-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
          {
            filename: 'repository_dependencies-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
          {
            filename: 'combined-1.0.0-2017-06-06.csv',
            sha256: '589b1c2ab88346074e98966ab34caccc111e43c1ed8d23a6a5e2599b318493fc',
            size: '512MB',
            rows: '2,000,000',
            href: '#'
          },
        ]
      }
    }
  end

  def latest_open_data_release_number
    open_data_releases.keys.first
  end

  def latest_open_data_release_date
    open_data_releases.values.first[:date]
  end

  def open_data_release(version)
    open_data_releases[version]
  end
end
