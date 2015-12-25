# Libraries.io

All the package managers

## Big Features

- Comprehensive Search
- Alternative/Related Projects suggestions
- Recommendation engine

## Getting started

Install and run the deps

```sh
 brew install postgres elasticsearch rbenv ruby-build
 # run postgres & eleasticsearch
```

Perform the sacred ruby voodoo

```sh
 rbenv install 2.3.0
 gem install bundler
 rbenv rehash
 bundle
```

Fight entropy with schemas

```sh
 rake db:create db:migrate
 rake projects:reindex
```

Go create a Personal access token on GitHub. Copy the token, for you will need it to pay the ferryman.

Lure rails into slurping down some data

```sh
 rails c
 irb> AuthToken.new(token: "<ure github token here>").save
 irb> Repositories::NPM.update "pictogram"
 irb> Repositories::Rubygems.update "split"
 irb> Repositories::Bower.update "sbteclipse"
```

I cannot take you any further. Offer up the magic flute to the spectral wolf, he will guide you onwards.

```sh
rails s
```

[Godspeed](http://xkcd.com/461/)
