# Adding support for a new package manager

- Add new file to `/app/models/package_manager`

- Implement minimum amount of methods

  - #project
  - #project_names
  - #mapping

- Implement extra methods where possible

  - #versions
  - #dependencies
  - #recent_names
  - #install_instructions
  - #formatted_name

- Implement url methods where possible

  - #package_link
  - #download_url
  - #documentation_url
  - #check_status_url

- Set constants

  - HAS_VERSIONS
  - HAS_DEPENDENCIES
  - LIBRARIAN_SUPPORT
  - URL
  - COLOR

- Add tasks to `download.rake`

- Add support to watcher

- Add Biblothecary support

- Add icon to pictogram
