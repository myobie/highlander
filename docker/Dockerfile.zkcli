# https://docs.docker.com/engine/reference/builder/
# https://hub.docker.com/r/jplock/zookeeper/

# latest at the time of writing was 3.4.8
FROM jplock/zookeeper:3.4.8
COPY zoo.cfg /opt/zookeeper/conf/zoo.cfg
ENTRYPOINT ["/opt/zookeeper/bin/zkCli.sh"]
CMD ["help"]
