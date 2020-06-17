FROM ruby:2.7.0

RUN apt-get update && apt-get install -y net-tools
RUN gem install mongo --version 2.12.1
RUN gem install faker
RUN gem install slop

ADD lb_up.rb /home/
CMD ruby /home/lb_up.rb -h $HOSTNAME
