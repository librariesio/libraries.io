FROM ruby:2.6.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev nodejs libicu-dev cmake git

ENV APP_HOME /libraries.io
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
# throw errors if Gemfile has been modified since Gemfile.lock

RUN bundle config --global frozen 1

ADD Gemfile* $APP_HOME/
RUN bundle install --jobs=4

ADD . $APP_HOME

ARG REVISION_ID
RUN echo $REVISION_ID > REVISION
ENV REVISION_ID $REVISION_ID

RUN RAILS_ENV=production bundle exec rake assets:precompile
