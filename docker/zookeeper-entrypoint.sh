#!/bin/bash

echo $MYID is my id

# wait until docker-compose gets all of the zookeeper containers running
# partially to start up the zookeeper cluster.
for host in 'zookeeper1' 'zookeeper2' 'zookeeper3' 'zookeeper4' 'zookeeper5'
do
    # http://stackoverflow.com/questions/6118948/bash-loop-ping-successful
    ((count = 10))
    while [[ $count -ne 0 ]] ; do
        ping -c 1 $host > /dev/null 2> /dev/null
        rc=$?
        if [[ $rc -eq 0 ]] ; then
            ((count = 1))
        fi
        sleep 1
        ((count = count - 1))
    done

    if [[ $rc -ne 0 ]] ; then
        echo $host never ready for zookeeper$MYID
        exit 1
    fi
done

mkdir /var/zookeeper
echo $MYID > /var/zookeeper/myid
/opt/zookeeper/bin/zkServer.sh start-foreground
# > /dev/null 2> /dev/null
