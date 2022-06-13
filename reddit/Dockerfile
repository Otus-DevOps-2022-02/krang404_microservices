FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y mongodb-server ruby-full ruby-dev build-essential \
    && gem install bundler \
    && gem update --system 3.2.3 \
    && gem install mongo \
    && mkdir reddit

COPY ./ /reddit
COPY mongod.conf /etc/mongod.conf
COPY start.sh /start.sh

RUN cd /reddit && rm Gemfile.lock && bundle install \
    && chmod 0777 /start.sh

CMD ["/start.sh"]
