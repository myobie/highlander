# https://docs.docker.com/engine/reference/builder/
# https://hub.docker.com/r/jplock/zookeeper/

# latest at the time of writing was 3.4.8
FROM jplock/zookeeper:3.4.8
ARG myid
COPY zoo.cfg /opt/zookeeper/conf/zoo.cfg
COPY zookeeper-entrypoint.sh /opt/zookeeper/bin/zookeeper-entrypoint.sh
ENV MYID=$myid
ENTRYPOINT ["bash", "/opt/zookeeper/bin/zookeeper-entrypoint.sh"]
