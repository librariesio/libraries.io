FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y build-essential
RUN apt-get install -y libpq-dev libxml2-dev libxslt1-dev nodejs libicu-dev cmake

ENV APP_HOME /libraries.io
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install --jobs=4

ADD . $APP_HOME
