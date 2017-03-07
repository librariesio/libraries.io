# Adding support for a new package manager

Libraries.io already has support for most of the largest package managers but there are many more
that we've not added yet. This guide will take you through the steps for adding support for another.

Adding support for a new package manager is fairly easy assuming that the package manager repository has an API for extracting data about it's packages over http.

## Add the `PackageManager` class file

Add new file to [`app/models/package_manager`](../app/models/package_manager), this will be a ruby class so the filename should be all lower case and end in `.rb`, for example: `app/models/package_manager/foobar.rb`

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

### `#project_names`

Libraries needs to know all of the names of the projects available in a package manager to be able to index them, this method should return an array of strings of names.

Different package managers provide ways of getting this data, here are some examples:

- [npm](../app/models/package_manager/npm.rb) provides one huge json endpoint containing all the pacakges, we pluck just the keys from the top level object in the response:
```ruby
def self.project_names
  get("https://registry.npmjs.org/-/all").keys[1..-1]
end
```

- [Haxelib](../app/models/package_manager/haxelib.rb) lists all the project names on a html page, so we use nokogiri to pluck them all out:
```ruby
def self.project_names
  get_html("https://lib.haxe.org/all/").css('.project-list tbody th').map{|th| th.css('a').first.try(:text) }
end
```

- [Julia](../app/models/package_manager/julia.rb) stores all the packages in a git repository, here we clone the repo, list the top level folder names, not ideal but it works:
```ruby
def self.project_names
  @project_names ||= `rm -rf Specs;git clone https://github.com/JuliaLang/METADATA.jl --depth 1; ls METADATA.jl`.split("\n")
end
```

### `#project`

Once we have a list of package names, we need to be able to get the information for each package by it's name from the registry. This is also used for syncing/updating a package we already know about when a new version is published.

This method takes a string of the name as an argument and usually makes a http request to the registry for the given name and returns a ruby hash of information, often parsed from json or xml.

Some examples:

- [Packagist](../app/models/package_manager/packagist.rb) has a JSON endpoint and we select just the `package` attribute from the response:
```ruby
def self.project(name)
  get("https://packagist.org/packages/#{name}.json")['package']
end
```

- [npm](../app/models/package_manager/npm.rb) has a JSON endpoint but we need to escape `/` for scoped module names:
```ruby
def self.project(name)
  get("http://registry.npmjs.org/#{name.gsub('/', '%2F')}")
end
```

- [Hackage](../app/models/package_manager/hackage.rb) doesn't have a JSON endpoint for package information so we scrape the html of the page instead:
```ruby
def self.project(name)
  {
    name: name,
    page: get_html("http://hackage.haskell.org/package/#{name}")
  }
end
```

### `#mapping`

After getting the information about a package from the registry, we need to format that data into something that will fit nicely in the Libraries.io database, the mapping method takes the result of the `#project` method and returns a hash with some or all of the following keys:

- `name` - The name of the project, this is usually the same as originally passed to `#project`
- `description` - description of the project, usually a couple of paragraphs, not the whole readme
- `repository_url` - url where the source code for the project is hosted, often a GitHub, GitLab or Bitbucket repo page
- `homepage` - url for the homepage of the project if different from the `repository_url`
- `licenses` - an array of SPDX license short names that the project is licensed under, eg `['MIT', 'GPL-2.0']`
- `keywords_array` - an array of keywords or tags that can be used to categorize the project

Here's an example from [Cargo](../app/models/package_manager/cargo.rb):

```ruby
def self.mapping(project)
  {
    :name => project['crate']['id'],
    :homepage => project['crate']['homepage'],
    :description => project['crate']['description'],
    :keywords_array => Array.wrap(project['crate']['keywords']),
    :licenses => project['crate']['license'],
    :repository_url => repo_fallback(project['crate']['repository'], project['crate']['homepage'])
  }
end
```

## Implement extra methods where possible

Not all package managers have these concepts but lots do, more features in Libraries.io can be enabled if these methods are implemented in a PackageManager class:

### `#versions`



### `#dependencies`



### `#recent_names`

For package managers with a lot of packages, downloading the full list of names can take a long time. If you can provide a list of names of recently added/updated packages then Libraries.io can check that on a more regular basis. It should return a list of names in the same way that `#project_names` does, for example:

- [Pub](../app/models/package_manager/pub.rb)'s project list page is ordered by most recently updated so we can just grab the first page of packages and map the names out:
```ruby
def self.recent_names
  get("https://pub.dartlang.org/api/packages?page=1")['packages'].map{|project| project['name'] }
end
```

### `#install_instructions`

Many package managers have a command line interface for installing individual packages, if you add this method, Libraries.io will show the instructions on the project page so anyone can easily install it.

This method is passed a `project` object and optionally a version number, here's some examples:

- [Rubygems](../app/models/package_manager/rubygems.rb) adds a `-v` flag if a version is passed
```ruby
def self.install_instructions(project, version = nil)
  "gem install #{project.name}" + (version ? " -v #{version}" : "")
end
```

- [Go](../app/models/package_manager/go.rb) cli doesn't have support for specifying a version so it's ignored
```ruby
def self.install_instructions(project, version = nil)
  "go get #{project.name}"
end
```

### `#formatted_name`

If the package manager's official name doesn't fit with Ruby's class name rules you can add it's official name in this method, for example [`npm`](../app/models/package_manager/npm.rb) is always lower case, the class name is `NPM` so we have added the following:

```ruby
def self.formatted_name
  'npm'
end
```

## Implement url methods where possible

### `#package_link`



### `#download_url`


### `#documentation_url`


### `#check_status_url`



## Set constants

### `HAS_VERSIONS`


### `HAS_DEPENDENCIES`


### `LIBRARIAN_SUPPORT`


### `URL`


### `COLOR`



## Add tasks to `download.rake`



## Add support to watcher



## Add Biblothecary support



## Add icon to pictogram
