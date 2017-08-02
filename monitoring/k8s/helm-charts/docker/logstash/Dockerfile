FROM java:8u111-jre

# Download & Configure logstash
# beats input on 5043
EXPOSE 5043

ENV VERSION 5.4.0
ENV PLATFORM linux-x86_64
ENV DOWNLOAD_URL "https://artifacts.elastic.co/downloads/logstash/logstash-${VERSION}.tar.gz"

RUN cd /tmp \
  && echo "Install Logstash..." \
  && wget -O logstash.tar.gz "$DOWNLOAD_URL" \
  && tar -xf logstash.tar.gz \
  && mv logstash-$VERSION /logstash

WORKDIR /logstash

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENV ELASTICSEARCH_URL "http://elasticsearch:9200"

CMD ["/run.sh"]