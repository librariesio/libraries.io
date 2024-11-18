FROM ruby:3.2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev nodejs libicu-dev cmake git
RUN curl -sSL https://sdk.cloud.google.com | CLOUDSDK_INSTALL_DIR=/usr/local bash
ENV PATH $PATH:/usr/local/google-cloud-sdk/bin

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

# Rails needs both of these secret env vars to boot, so we're stubbing out fake values. We also just remove the credential file
# here to skip the decryption since we have fake values. Should be fine just for asset compilation.
RUN SECRET_KEY_BASE=1111111111 RAILS_MASTER_KEY=11111111 RAILS_ENV=production bundle exec rake assets:precompile
