FROM fluent/fluentd:v0.12

RUN fluent-gem install elasticsearch -v 7.17.0
RUN fluent-gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.18.1
RUN fluent-gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0

ADD fluent.conf /fluentd/etc
