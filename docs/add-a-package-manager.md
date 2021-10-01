# Adding support for a new package manager

Libraries.io already has support for most of the largest package managers but there are many more
that we've not added yet. This guide will take you through the steps for adding support for another.

Adding support for a new package manager is fairly easy assuming that the package manager repository has an API for extracting data about its packages over the internet. Follow these steps:

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

- [npm](../app/models/package_manager/npm.rb) provides one huge json endpoint containing all the packages, we pluck just the keys from the top level object in the response:
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

Once we have a list of package names, we need to be able to get the information for each package by its name from the registry. This is also used for syncing/updating a package we already know about when a new version is published.

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
def self.mapping(raw_project)
  {
    :name => raw_project['crate']['id'],
    :homepage => raw_project['crate']['homepage'],
    :description => raw_project['crate']['description'],
    :keywords_array => Array.wrap(raw_project['crate']['keywords']),
    :licenses => raw_project['crate']['license'],
    :repository_url => repo_fallback(raw_project['crate']['repository'], raw_project['crate']['homepage'])
  }
end
```

## Implement extra methods where possible

Not all package managers have these concepts but lots do, more features in Libraries.io can be enabled if these methods are implemented in a PackageManager class:

### `#versions`

For package managers that have a concept of discrete versions being published.

This method takes the returned data from the `#project` method and should return an array of hashes, one for each version, with a `number` and the date that the version was originally `published_at`.

Here's an example from [NuGet](../app/models/package_manager/nu_get.rb):

```ruby
def self.versions(raw_project, _name)
  raw_project[:releases].map do |item|
    {
      number: item['catalogEntry']['version'],
      published_at: item['catalogEntry']['published']
    }
  end
end
```

### `#one_version`

For package managers that we can update using a single version instead of all versions.

This method should take the returned data from the `#project` method and should return a single version, with the same data
that `versions()` returns.

```ruby
def self.one_version(raw_project, version_string)
  raw_project["versions"]
    .find { |v| v["number"] == version_string }
    .map do |item|
      number: item["number"],
      published_at: item["published"]
    end
end
```

### `#dependencies`

For package managers that have a concept of versions and versions having dependencies.

This method returns the dependencies for a particular version of a package, so it receives a `name`, `version` and optionally the returned data from the `#project` method and should return an array of hashes, one for each dependency.

Each dependency hash should include the following attributes:

- `project_name` - the name of the package of the dependency
- `requirements` - the version requirements of this dependency, for example `~> 2.0`
- `kind` - regular dependencies are `runtime` but this could also be `development`, `test`, `build` or something else

The can also potentially have extra attributes:

- `optional` - some package managers have the concept of optional dependencies, if yours does, set this as a boolean
- `platform` - this will almost always be `self.name.demodulize`, the same platform as the package manager, but if dependencies come from a different package manager you can override it

Example from [Haxelib](../app/models/package_manager/haxelib.rb):

```ruby
def self.dependencies(name, version, _mapped_project)
  json = get_json("https://lib.haxe.org/p/#{name}/#{version}/raw-files/haxelib.json")
  return [] unless json['dependencies']
  json['dependencies'].map do |dep_name, dep_version|
    {
      project_name: dep_name,
      requirements: dep_version.empty? ? '*' : dep_version,
      kind: 'runtime',
      platform: self.name.demodulize
    }
  end
rescue
  []
end
```

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
def self.install_instructions(db_project, version = nil)
  "gem install #{db_project.name}" + (version ? " -v #{version}" : "")
end
```

- [Go](../app/models/package_manager/go.rb) cli doesn't have support for specifying a version so it's ignored
```ruby
def self.install_instructions(db_project, version = nil)
  "go get #{db_project.name}"
end
```

### `#formatted_name`

If the package manager's official name doesn't fit with Ruby's class name rules you can add its official name in this method, for example [`npm`](../app/models/package_manager/npm.rb) is always lower case, the class name is `NPM` so we have added the following:

```ruby
def self.formatted_name
  'npm'
end
```

## Implement url methods where possible

If the package manager registry has a predictable url structure, we can generate useful urls for each project that are used where available:

### `#package_link`

If the package manager registry website has individual pages for each package, add this method to return a url for it.

It takes a `project` object and an optional `version` number, for example:

```ruby
def self.package_link(db_project, version = nil)
  "https://rubygems.org/gems/#{db_project.name}" + (version ? "/versions/#{version}" : "")
end
```

### `#download_url`

If the package manager provides predictable urls to the tar ball or zip archive of the package, add this method to return a url for it.

It takes a package `name` and an optional `version` number, for example:

```ruby
def self.download_url(db_project, version = nil)
  "https://rubygems.org/downloads/#{db_project.name}-#{version}.gem"
end
```

### `#documentation_url`

If the package manager provides hosted documentation for each package, add this method to return a url for it.

It takes a package `name` and an optional `version` number, for example:

```ruby
def self.documentation_url(name, version = nil)
  "http://www.rubydoc.info/gems/#{name}/#{version}"
end
```

### `#check_status_url`

Libraries will try and ping the `#package_link` url on a regular basis to check for a 200 status code, if the package manager registry always returns a 200 or doesn't have a `#package_link` method, you can add this method to provide a different url that will return a 200 if the package still exists or a 404 if it's been removed.

It takes a `project` object, for example:

```ruby
def self.check_status_url(db_project)
  "https://rubygems.org/api/v1/versions/#{db_project.name}"
end
```

## Set constants

Constants are added to each `PackageManager` to provide more meta data about the level of support that Libraries.io has for that package manager:

### `HAS_VERSIONS`

If the `PackageManager` class has a `#versions` method then set this to `true`:

```ruby
HAS_VERSIONS = true
```

### `HAS_DEPENDENCIES`

If the `PackageManager` class has a `#dependencies` method then set this to `true`:

```ruby
HAS_DEPENDENCIES = true
```

### `BIBLIOTHECARY_SUPPORT`

If your package manager has the concept of a manifest, a file that lists dependencies for a repository, for example `Gemfile`, `package.json` and `setup.py`, then you can add support to [Bibliothecary](https://github.com/librariesio/bibliothecary) to parse dependencies from those manifests from repositories on GitHub, GitLab and Bitbucket.

If [Bibliothecary](https://github.com/librariesio/bibliothecary) already has support for parsing manifest files for this package manager set it to `true`:

```ruby
BIBLIOTHECARY_SUPPORT = true
```

### `BIBLIOTHECARY_PLANNED`

If it's possible that [Bibliothecary](https://github.com/librariesio/bibliothecary) support for parsing manifest files can be added for this package manager, but has not yet, set it to `true`:

```ruby
BIBLIOTHECARY_PLANNED = true
```

### `URL`

If the package manager has a website then set this to the full url with protocol:

```ruby
URL = 'https://rubygems.org'
```

### `COLOR`

Most application level package managers have a main programming language that they focus on, this should be set to the hex value for that language from the `github-linguist` gem, you can see the full list of colours in [`languages.yml`](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml)

```ruby
COLOR = '#701516'
```

### `HIDDEN`

This doesn't need to be set for any active package managers, but if one is shut down and should no longer be shown on the site set it to `true`:

```ruby
HIDDEN = true
```

## Add tasks to `download.rake`

Once your `PackageManager` class is ready you can add the required rake tasks to [`download.rake`](../lib/tasks/download.rake)

Depending on the size, popularity and frequency of updates there are different tasks to add:

### recent async

If there's a `#recent_names` method defined on the `PackageManager` class then Libraries.io can check for new updates frequently by calling `#import_recent_async` on the class, add a rake task that looks like this:

```ruby
desc 'Download recent Rubygems packages asynchronously'
task rubygems: :environment do
  PackageManager::Rubygems.import_recent_async
end
```

### new async

For package managers that don't have a proper concept of versions (Go and Bower are good examples that fall back to git tags), we don't need to check packages we already know about, the `#import_new_async` task will only download packages we don't already have in the database:

```ruby
desc 'Download new Bower packages asynchronously'
task bower: :environment do
  PackageManager::Bower.import_new_async
end
```

### all async

For the initial import of all packages, add an `foobar_all` task which calls `#import_async`, this will be ran on a daily basis if there's no `#recent_names` method defined:

```ruby
desc 'Download all Rubygems packages asynchronously'
task rubygems_all: :environment do
  PackageManager::Rubygems.import_async
end
```

### recent sync

For some package managers that the download process can't easily be parallelized (if it requires cloning a git repo for example), the import can be done synchronously instead with the following task that calls `#import` on the class:

```ruby
desc 'Download all Inqlude packages'
task inqlude: :environment do
  PackageManager::Inqlude.import
end
```

## Other repositories to be updated

Once the `PackageManager` class is ready, there's some optional updates that can be added to some other repositories to enable more functionality.

### Add support to Dispatch

[Dispatch](https://github.com/librariesio/dispatch) polls RSS feeds and JSON API endpoints every 30 seconds to check for new and updated packages and then enqueues jobs to download those packages. It helps reduce the load on the package manager registries and push new data into the system faster.

If your package manager has RSS feeds of new packages or recently updated packages then add each url to the [`RSS_SERVICES`](https://github.com/librariesio/dispatch/blob/master/dispatch.rb#L125) array, along with the class name of the package.

If your package manager has JSON API of new packages or recently updated packages then add each url to the [`JSON_SERVICES`](https://github.com/librariesio/dispatch/blob/master/dispatch.rb#L103) array, along with the class name of the package.

### Add Bibliothecary support

If your package manager has the concept of a manifest, a file that lists dependencies for a repository, then you can add support to [Bibliothecary](https://github.com/librariesio/bibliothecary) to parse dependencies from those manifests from repositories on GitHub, GitLab and Bitbucket.

Check out the documentation on adding support for a new package manager in the Bibliothecary repo: https://github.com/librariesio/bibliothecary

### Add icon to Pictogram

If your package manager has an icon, adding it to the [Pictogram](https://github.com/librariesio/pictogram) repository will enable it to show up on the site.

Check out the documentation on adding a logo for a new package manager in the Pictogram repo: https://github.com/librariesio/pictogram
