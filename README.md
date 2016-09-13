# Libraries.io

[![Build Status](https://circleci.com/gh/librariesio/libraries.io.svg?style=shield)](https://circleci.com/gh/librariesio/libraries.io)
[![Gitter chat](https://badges.gitter.im/librariesio/support.svg)](https://gitter.im/librariesio/support)
[![Code Climate](https://img.shields.io/codeclimate/github/librariesio/libraries.io.svg?style=flat)](https://codeclimate.com/github/librariesio/libraries.io)
[![Coverage Status](https://coveralls.io/repos/github/librariesio/libraries.io/badge.svg?branch=master)](https://coveralls.io/github/librariesio/libraries.io?branch=master)

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
 rbenv install 2.3.1
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
 irb> AuthToken.new(token: "<secure github token here>").save
 irb> Repositories::NPM.update "pictogram"
 irb> Repositories::Rubygems.update "split"
 irb> Repositories::Bower.update "sbteclipse"
```

I cannot take you any further. Offer up the magic flute to the spectral wolf, he will guide you onwards.

```sh
rails s
```

[Godspeed](http://xkcd.com/461/)
