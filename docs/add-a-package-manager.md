# Adding support for a new package manager

Libraries.io already has support for most of the largest package managers but there are many more
that we've not added yet. This guide will take you through the steps for adding support for another.

Adding support for a new package manager is fairly easy assuming that the package manager repository has an API for extracting data about it's packages over http.

## Add the PackageManager class file

Add new file to [`app/models/package_manager`](app/models/package_manager), this will be a ruby class so the filename should be all lower case and end in `.rb`, for example: `app/models/package_manager/foobar.rb`

The basic structure of the class should look like this:

```ruby
module PackageManager
  class Foobar < Base

  end
end
```

Note that the class name must begin with a capital letter and only contain letters, numbers and underscores, ideally the class name will match the formatting of the package managers official name, i.e. `CocoaPods`

## Implement minimum amount of methods

There are three basic methods that each package manager class needs to implement to enable minimal support in Libraries.io:

### #project_names

Libraries needs to know all of the names of the projects available in a package manager to be able to index them, this method should return an array of strings of names.

Different package managers provide ways of getting this data, here are some examples:

- [npm](app/models/package_manager/npm.rb) provides one huge json endpoint containing all the pacakges, we pluck just the keys from the top level object in the response:
```ruby
def self.project_names
  get("https://registry.npmjs.org/-/all").keys[1..-1]
end
```

- [Haxelib](app/models/package_manager/haxelib.rb) lists all the project names on a html page, so we use nokogiri to pluck them all out:
```ruby
def self.project_names
  get_html("https://lib.haxe.org/all/").css('.project-list tbody th').map{|th| th.css('a').first.try(:text) }
end
```

- [Julia](app/models/package_manager/julia.rb) stores all the packages in a git repository, here we clone the repo, list the top level folder names, not ideal but it works:
```ruby
def self.project_names
  @project_names ||= `rm -rf Specs;git clone https://github.com/JuliaLang/METADATA.jl --depth 1; ls METADATA.jl`.split("\n")
end
```

### #project

### #mapping

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
