FROM ruby:2.5.8-alpine as build

RUN apk add --update --no-cache \
      nodejs \
      yarn

ENV APP_HOME /hdm
WORKDIR $APP_HOME

COPY package.json $APP_HOME
COPY yarn.lock $APP_HOME
RUN yarn install --check-files

COPY . $APP_HOME

FROM ruby:2.5.8-alpine

RUN apk add --update --no-cache \
      binutils-gold \
      build-base \
      g++ \
      gcc \
      libstdc++ \
      libffi-dev \
      libc-dev \
      libxml2-dev \
      libxslt-dev \
      libgcrypt-dev \
      make \
      sqlite \
      sqlite-dev \
      # not needed for gems, but for runtime
      git \
      tzdata \
      # yarn # works without this but produces a short error, that yarn is not found

RUN gem install bundler -v 2.3.6

COPY --from=build /hdm /hdm
WORKDIR /hdm

RUN bundle check || bundle install --without test

# ENTRYPOINT ["/hdm/bin/entry.sh"]
CMD ["/hdm/bin/entry.sh"]
