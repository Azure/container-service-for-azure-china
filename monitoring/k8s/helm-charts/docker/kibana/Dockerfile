FROM java:8u111-jre

# Download & Configure kibana
EXPOSE 80

ENV KIBANA_VERSION 5.4.0
ENV PLATFORM linux-x86_64
ENV DOWNLOAD_URL "https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-${PLATFORM}.tar.gz"

RUN cd /tmp \
  && echo "Install Kibana..." \
  && wget -O kibana.tar.gz "$DOWNLOAD_URL" \
  && tar -xf kibana.tar.gz \
  && mv kibana-$KIBANA_VERSION-$PLATFORM /kibana

RUN apt-get update && apt-get install -y nginx apache2-utils

ARG USERNAME=azureuser
ARG PASSWORD=azureuser
RUN echo ${PASSWORD} | htpasswd -c -i /etc/nginx/.htpasswd ${USERNAME}
COPY nginx-site.conf /etc/nginx/sites-available/default
RUN service nginx reload

WORKDIR /kibana

ENV SERVER_PORT 5601
ENV SERVER_HOST "localhost"
ENV ELASTICSEARCH_URL "http://elasticsearch:9200"

CMD service nginx start && /kibana/bin/kibana --server.host=$SERVER_HOST --server.port=$SERVER_PORT --elasticsearch.url=$ELASTICSEARCH_URL
