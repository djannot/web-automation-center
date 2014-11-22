FROM jimmidyson/jruby:v1.7.11
RUN yum install -y git
WORKDIR /root
RUN git clone https://github.com/djannot/web-automation-center.git
WORKDIR /root/web-automation-center
RUN jruby -S bundle install
RUN echo "#!/bin/sh" > /start.sh;echo "export RAILS_ENV=production; cd /root/web-automation-center; jruby -S rails s trinidad" >> /start.sh; chmod +x /start.sh
ENTRYPOINT ["/start.sh"]
