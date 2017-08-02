FROM java:8u111-jre

# Download & Configure elasticsearch
EXPOSE 9200 9300

ENV VERSION 5.4.0
ENV PLATFORM linux-x86_64
ENV DOWNLOAD_URL "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}.tar.gz"

RUN cd /tmp \
  && apt update && apt install -y sudo uuid-runtime \
  && echo "Install Elasticsearch..." \
  && wget -O elasticsearch.tar.gz "$DOWNLOAD_URL" \
  && tar -xf elasticsearch.tar.gz \
  && mv elasticsearch-$VERSION /elasticsearch

WORKDIR /elasticsearch

COPY config /elasticsearch/config

RUN adduser --disabled-password --no-create-home --gecos "" --shell /sbin/nologin elasticsearch \
  && chown -R elasticsearch:elasticsearch /elasticsearch

ENV CLUSTER_NAME elasticsearch
ENV NODE_MASTER true
ENV NODE_DATA true
ENV NODE_INGEST true
ENV NETWORK_HOST 0.0.0.0
ENV DISCOVERY_SERVICE localhost
ENV NUMBER_OF_MASTERS 1

COPY run.sh /
RUN chmod +x /run.sh
CMD ["/run.sh"]
