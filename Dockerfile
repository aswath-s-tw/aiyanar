# FROM ruby:3.3.0


FROM debian:bullseye-slim as base
RUN apt update && apt install -y build-essential wget autoconf
RUN wget https://github.com/postmodern/ruby-install/releases/download/v0.9.3/ruby-install-0.9.3.tar.gz \
  && tar -xzvf ruby-install-0.9.3.tar.gz \
  && cd ruby-install-0.9.3/ \
  && make install
RUN ruby-install -p https://github.com/ruby/ruby/pull/9371.diff ruby 3.3.0
ENV PATH="/opt/rubies/ruby-3.3.0/bin:${PATH}"

# see update.sh for why all "apt-get install"s have to stay as one long line
RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

# see http://guides.rubyonrails.org/command_line.html#rails-dbconsole
RUN apt-get update && apt-get install -y sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment

COPY . .

RUN bundle exec rake assets:clobber assets:precompile
ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT true
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
