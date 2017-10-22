FROM ruby:2.3.3

EXPOSE 8080
ENV SERVICE_NAME kgcash
ENV SERVICE_PORT 8080

RUN apt-get update -qq && apt-get install -y build-essential mysql-client nodejs

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

RUN mkdir /kgcash
WORKDIR /kgcash

ADD . /kgcash

RUN chmod a+x run.sh

ENTRYPOINT ["/kgcash/run.sh"]
