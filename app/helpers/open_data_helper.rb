# frozen_string_literal: true
module OpenDataHelper
  def open_data_releases
    {
      '1.0.0' => {
        date: 'June 15, 2017',
        filename: 'Libraries.io-open-data-1.0.0.zip',
        md5: 'be8015f7e70481da6b43af63372be626',
        size: '5.9GB',
        rows: '200 million',
        download: 'https://zenodo.org/record/808273/files/Libraries.io-open-data-1.0.0.zip'
      },
      '1.0.1' => {
        date: 'July 21, 2017',
        filename: 'Libraries.io-open-data-1.0.1.zip',
        md5: 'e73506370d920431cea1ed95c19338b5',
        size: '5.9GB',
        rows: '200 million',
        download: 'https://zenodo.org/record/833207/files/Libraries.io-open-data-1.0.1.zip'
      },
      '1.1.1' => {
        date: 'November 29, 2017',
        filename: 'Libraries.io-open-data-1.1.1.tar.gz',
        md5: '053fcb882d0ee038632a819a7829e1b8',
        size: '7.1GB',
        rows: '311 million',
        download: 'https://zenodo.org/record/1068916/files/Libraries.io-open-data-1.1.1.tar.gz'
      },
      '1.2.0' => {
        date: 'March 13, 2018',
        filename: 'Libraries.io-open-data-1.2.0.tar.gz',
        md5: '5ada269fa799265b5ffc32902ccfbce1',
        size: '8.7GB',
        rows: '397 million',
        download: 'https://zenodo.org/record/1196312/files/Libraries.io-open-data-1.2.0.tar.gz'
      },
      '1.4.0' => {
        date: 'December 22, 2018',
        filename: 'Libraries.io-open-data-1.4.0.tar.gz',
        md5: '5bf302e6944cb1a8283a316f65b24093',
        size: '13.1 GB',
        rows: '495 million',
        download: 'https://zenodo.org/record/2536573/files/Libraries.io-open-data-1.4.0.tar.gz'
      },
      '1.6.0' => {
        date: 'January 12, 2020',
        filename: 'libraries-1.6.0-2020-01-12.tar.gz',
        md5: '4f2275284b86827751bb31ce74238b15',
        size: '24 GB',
        rows: '495 million',
        download: 'https://zenodo.org/record/3626071/files/libraries-1.6.0-2020-01-12.tar.gz'
      }
    }
  end

  def latest_open_data_release
    open_data_releases[latest_open_data_release_number]
  end

  def latest_open_data_release_number
    open_data_releases.keys.last
  end

  def latest_open_data_release_date
    latest_open_data_release[:date]
  end

  def open_data_release(version)
    open_data_releases[version]
  end
end
