FROM ruby:2.6.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev nodejs libicu-dev cmake git

ENV APP_HOME /libraries.io
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

ADD Gemfile* $APP_HOME/
RUN bundle install --jobs=4

ADD . $APP_HOME
RUN bundle exec rake assets:precompile

RUN git show-ref --head --dereference HEAD |cut -d ' ' -f 1 > REVISION
