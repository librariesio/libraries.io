FROM ruby:2.5.1
RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y libpq-dev libxml2-dev libxslt1-dev nodejs libicu-dev cmake

ENV APP_HOME /libraries.io
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

ADD Gemfile* $APP_HOME/
RUN bundle install --jobs=4

ADD . $APP_HOME
RUN bundle exec rake assets:precompile
