# Libraries.io &#128218;

[![Build Status](https://circleci.com/gh/librariesio/libraries.io.svg?style=shield)](https://circleci.com/gh/librariesio/libraries.io)
[![Slack chat](https://slack.libraries.io/badge.svg)](https://slack.libraries.io)
[![Code Climate](https://img.shields.io/codeclimate/github/librariesio/libraries.io.svg?style=flat)](https://codeclimate.com/github/librariesio/libraries.io)
[![Test Coverage](https://codeclimate.com/github/librariesio/libraries.io/badges/coverage.svg)](https://codeclimate.com/github/librariesio/libraries.io/coverage)

Libraries.io helps developers find new open source libraries, modules and frameworks and keep track of ones they depend upon.

## Contributors

Over 25 people have contributed to the project, you can see them all here: https://github.com/librariesio/libraries.io/graphs/contributors

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
```

Next, you'll need to make sure that you have PostgreSQL and Redis installed. This can be done easily on OSX using [Homebrew](http://mxcl.github.io/homebrew/) or postgres can be installed by using [http://postgresapp.com](http://postgresapp.com). Please also see these [further instructions for installing Postgres via Homebrew](http://www.mikeball.us/blog/setting-up-postgres-with-homebrew/).

```bash
brew install postgres phantomjs elasticsearch@2.4 redis
```

Remember to start the services!

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
bundle exec rake db:create db:migrate
```

Go create a [Personal access token on GitHub](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) (only requires `public_repo` access), then we can download some sample data:

```sh
 bundle exec rails c
 irb> AuthToken.new(token: "<secure github token here>").save
 irb> PackageManager::NPM.update "pictogram"
 irb> PackageManager::Rubygems.update "split"
 irb> PackageManager::Bower.update "sbteclipse"
```

You can then index that data into elasticsearch with the following rake task:

```bash
rake projects:reindex github:reindex_repos github:reindex_issues
```

It is normal to see:

```bash
[!!!] Index does not exist (Elasticsearch::Transport::Transport::Errors::NotFound)
[!!!] Index does not exist (Elasticsearch::Transport::Transport::Errors::NotFound)
[!!!] Index does not exist (Elasticsearch::Transport::Transport::Errors::NotFound)
```

If you are working on anything related to the email-generation code, you can use [MailCatcher](https://github.com/sj26/mailcatcher).
Since we use Bundler, please read the [following](https://github.com/sj26/mailcatcher#bundler) before using MailCatcher.

Almost there! Now all we have to do is start up the Rails server and point
our browser to <http://localhost:3000>

```bash
bundle exec rails s
```

You're now ready to go with the basic libraries.io app setup, to grab more data check out the extensive list of rake tasks with the following command:

```bash
rake -T
```

### Github authentication and connection

To enable Github authentication go and register a new [GitHub OAuth Application](https://github.com/settings/applications/new). Your development configuration should look something like this:

<img width="561" alt="screen shot 2016-12-18 at 21 54 35" src="https://cloud.githubusercontent.com/assets/564113/21299762/a7bfaace-c56c-11e6-834c-ff893f79cec3.png">

If you're deploying this to production, just replace `http://localhost:3000` with your application's URL.

You'll need to register an additional application to enable each of public and private projects, using `http://localhost:3000/auth/github_public/callback` and `http://localhost:3000/auth/github_private/callback` as the callbacks respectively. You do not need to do private projects unless you require that functionality.

Once you've created your application you can then then add the following to your `.env`:

```bash
GITHUB_KEY=yourclientidhere
GITHUB_SECRET=yourclientsecrethere
GITHUB_PUBLIC_KEY=yourpublicclientidhere
GITHUB_PUBLIC_SECRET=yourpublicclientsecrethere
GITHUB_PRIVATE_KEY=yourprivateclientidhere
GITHUB_PRIVATE_SECRET=yourprivateclientsecrethere
```

### Repository sync

To enable repository sync you will need to run a sidekiq worker:

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

Note that if you start the sync before starting sidekiq you will probably need to stop the jobs and delete the queues then restart sidekiq and start the sync again to make it work. It should take seconds to complete.

To monitor sidekiq jobs, and administer them go to [the sidekiq admin screen](http://localhost:3000/sidekiq/).

### Tests

Standard RSpec/Capybara tests are used for testing the application. The tests can be run with `bundle exec rake`.

You can set up the test environment with `bundle exec rake db:test:prepare`, which will create the test DB and populate its schema automatically. You don't need to do this for every test run, but it will let you easily keep up with migrations. If you find a large number of tests are failing you should probably run this.

If you are using the omniauth environment variables
(GITHUB_KEY, GITHUB_SECRET etc)
for **another** project, you will need to either
 * unset them before running your tests or
 * reset the omniauth environment variables after creating a GitHub (omniauth) application for this project

as it will use it to learn more about the developers and for pull requests.

### Project Wiki

If you would like to know more about the software you just installed, how it works and our roadmap for future features then you'll find all of this [in the wiki](https://github.com/librariesio/libraries.io/wiki).

### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so we don't break it in a future version unintentionally.
 * Send a pull request. Bonus points for topic branches.

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Copyright

Copyright (c) 2016 Andrew Nesbitt. See [LICENSE](https://github.com/librariesio/libraries.io/blob/master/LICENSE.txt) for details.
