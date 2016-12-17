# Libraries.io &#128218;

[![Build Status](https://circleci.com/gh/librariesio/libraries.io.svg?style=shield)](https://circleci.com/gh/librariesio/libraries.io)
[![Slack chat](https://slack.libraries.io/badge.svg)](https://slack.libraries.io)
[![Code Climate](https://img.shields.io/codeclimate/github/librariesio/libraries.io.svg?style=flat)](https://codeclimate.com/github/librariesio/libraries.io)
[![Test Coverage](https://codeclimate.com/github/librariesio/libraries.io/badges/coverage.svg)](https://codeclimate.com/github/librariesio/libraries.io/coverage)

Libraries.io helps developers find new open source libraries, modules and frameworks and keep track of ones they depend upon.

## Contributors

Over 20 different people have contributed to the project, you can see them all here: https://github.com/librariesio/libraries.io/graphs/contributors

## Development

Source hosted at [GitHub](https://github.com/librariesio/libraries.io).
Report issues/feature requests on [GitHub Issues](https://github.com/librariesio/libraries.io/issues). Follow us on Twitter [@librariesio](https://twitter.com/librariesio). We also hangout on [Slack](https://slack.libraries.io).

### Getting Started

New to Ruby? No worries! You can follow these instructions to install a local server, or you can use the included Vagrant setup.

#### Installing a Local Server

First things first, you'll need to install Ruby 2.3.3. I recommend using the excellent [rbenv](https://github.com/rbenv/rbenv),
and [ruby-build](https://github.com/rbenv/ruby-build)

```bash
brew install rbenv ruby-build
rbenv install 2.3.3
rbenv global 2.3.3
```

Next, you'll need to make sure that you have PostgreSQL installed. This can be
done easily on OSX using [Homebrew](http://mxcl.github.io/homebrew/) or by using [http://postgresapp.com](http://postgresapp.com). Please see these [further instructions for installing Postgres via Homebrew](http://www.mikeball.us/blog/setting-up-postgres-with-homebrew/).

```bash
brew install postgres phantomjs elasticsearch
```

On Debian-based Linux distributions you can use apt-get to install Postgres:

```bash
sudo apt-get install postgresql postgresql-contrib libpq-dev
```

Now, let's install the gems from the `Gemfile` ("Gems" are synonymous with libraries in other
languages).

```bash
gem install bundler && rbenv rehash
bundle install
```

Once all the gems are installed, we'll need to create the databases and
tables. Rails makes this easy through the use of "Rake" tasks.

```bash
bundle exec rake db:create:all
bundle exec rake db:migrate
```

Go create a Personal access token on GitHub, then we can download some sample data:

```sh
 rails c
 irb> AuthToken.new(token: "<secure github token here>").save
 irb> Repositories::NPM.update "pictogram"
 irb> Repositories::Rubygems.update "split"
 irb> Repositories::Bower.update "sbteclipse"
```

You can then index that data into elasticsearch with the following rake task:

```bash
rake projects:reindex github:reindex_repos github:reindex_issues
```

If you are working on anything related to the email-generation code, you can use [MailCatcher](https://github.com/sj26/mailcatcher).
Since we use Bundler, please read the [following](https://github.com/sj26/mailcatcher#bundler) before using MailCatcher.

Almost there! Now all we have to do is start up the Rails server and point
our browser to <http://localhost:3000>

```bash
bundle exec rails s
```

### Tests

Standard RSpec/Capybara tests are used for testing the application. The tests can be run with `bundle exec rake`.

You can set up the test environment with `bundle exec rake db:test:prepare`, which will create the test DB and populate its schema automatically. You don't need to do this for every test run, but it will let you easily keep up with migrations. If you find a large number of tests are failing you should probably run this.

If you are using the omniauth environment variables
(GITHUB_KEY, GITHUB_SECRET etc)
for **another** project, you will need to either
 * unset them before running your tests or
 * reset the omniauth environment variables after creating a GitHub (omniauth) application for this project

as it will use it to learn more about the developers and for pull requests.

### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so we don't break it in a future version unintentionally.
 * Send a pull request. Bonus points for topic branches.

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Copyright

Copyright (c) 2016 Andrew Nesbitt. See [LICENSE](https://github.com/librariesio/libraries.io/blob/master/LICENSE.txt) for details.
