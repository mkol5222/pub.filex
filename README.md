# CPFEEDMAN - handling Check Point Network Feed objects notifications

## Notifications receiver

Configuration:
| Parameter | Description | Sample |
|-----------|-------------|--------|
| MYAPP_QUEUE_URL | SQS queue with update notification messages |https://sqs.eu-north-1.amazonaws.com/141317330670/my-queue123 |
| MYAPP_SQS_VPCE | Optional, if using VPC endpoints |  |
| MYAPP_AWS_ACCESS_KEY_ID | AWS access key ID |  |
| MYAPP_AWS_SECRET_ACCESS_KEY | AWS secret access key |  |
| MYAPP_AWS_SESSION_TOKEN | optional AWS session token |  |
| MYAPP_AWS_REGION | AWS region | eu-north-1 |
| MYAPP_ASSUME_ROLE | optional IAM role ARN to assume; it should allow SQS messages to be received and deleted | arn:aws:iam::141317330670:role/SQSReadOnlyRole |
| MYAPP_STS_URL | optional STS endpoint URL | https://sts.eu-north-1.amazonaws.com |
| MYAPP_INSECURE | optional flag to allow insecure connections - HTTPS client not validating server certificates | 0 |
| MYAPP_CA_BUNDLE_PATH | optional path to CA bundle to configure HTTPS client |  |
| MYAPP_SKIP_MANAGEMENT_HA_ACTIVE_CHECK | optional flag to skip management HA active check | 0 |
| MYAPP_LOG_FILE_PATH | optional path to log file | /var/log/cpfeedman.log |
| MYAPP_FEEDS_MAP_PATH | optional path to feeds map file | /home/admin/feeds.jsonl |

## Message format

```json
{"Env":"dev","Projects":"prometheus,cicd-jenkins,fluent-bit,kube-system"}
```

## Feed map (which gw have which feeds)

`feeds.sh` producing `feeds.jsonl`
```bash
#!/bin/bash

mgmt_cli -r true show simple-gateways details-level full limit 100 --format json | jq -r -c '.objects[] | {gw:.name, ip: ."ipv4-address"}' | while read gw; do
  name=$(echo $gw | jq -r '.gw')
  ip=$(echo $gw | jq -r '.ip')
  #echo "Gateway: $name, IP: $ip"
  cprid_util -server "$ip" -verbose rexec -rcmd dynamic_objects -efo_show | grep -Po '(?<=object name : )(.*)' | while read feed; do
    jq -n -c -r --arg feed "$feed" --arg ip "$ip" --arg gw "$name" '{"feed": $feed, gw: $gw, ip: $ip}'
  done
done | tee feeds.jsonl
```

`feeds.jsonl`
```json
{"feed":"feed_dev_airflow","gw":"ctrl--vmss-e2e7083a_13--AUTOMAGIC-VMSS-E2E7083A","ip":"48.220.48.4"}
{"feed":"feed_dev_cicd-jenkins","gw":"ctrl--vmss-e2e7083a_13--AUTOMAGIC-VMSS-E2E7083A","ip":"48.220.48.4"}
{"feed":"feed_dev_ufotracing","gw":"ctrl--vmss-e2e7083a_13--AUTOMAGIC-VMSS-E2E7083A","ip":"48.220.48.4"}
{"feed":"feed_dev_rh","gw":"ctrl--vmss-e2e7083a_13--AUTOMAGIC-VMSS-E2E7083A","ip":"48.220.48.4"}
{"feed":"feed_serv_ip","gw":"ctrl--vmss-e2e7083a_13--AUTOMAGIC-VMSS-E2E7083A","ip":"48.220.48.4"}
{"feed":"quic_cloud","gw":"ctrl--vmss-e2e7083a_13--AUTOMAGIC-VMSS-E2E7083A","ip":"48.220.48.4"}
```

### Watchdog

```bash
cpwd_admin start -name CPFEEDMAN -path /home/admin/cpfeedman -command "/home/admin/cpfeedman /home/admin/.envrc" -slp_timeout 1 -retry_limit u 

watch -d 'cpwd_admin list | grep CPFEEDMAN'

cpwd_admin list | grep CPFEEDMAN

cpwd_admin stop -name CPFEEDMAN -path /home/admin/cpfeedman -command "/home/admin/cpfeedman /home/admin/.envrc"

cpwd_admin del -name CPFEEDMAN
ps ax | grep cpfeedman
```

### Install

```bash
# on cpman
mkdir /opt/cpfeedman

curl_cli -k -o /opt/cpfeedman/cpfeedman -L https://github.com/mkol5222/pub.filex/raw/refs/heads/cpfeedman/cpfeedman
chmod +x /opt/cpfeedman/cpfeedman

ps ax | grep cpfeedman
cpwd_admin list | grep CPFEEDMAN
cpwd_admin del -name CPFEEDMAN
cpwd_admin list | grep CPFEEDMAN
ps ax | grep cpfeedman
kill -9 22624
ps ax | grep cpfeedman

cp /home/admin/.envrc /opt/cpfeedman/.envrc

file /opt/cpfeedman/cpfeedman

cat /opt/cpfeedman/.envrc
cat /opt/cpfeedman/.envrc | grep feeds.jsonl
cat /opt/cpfeedman/feeds.jsonl

cpwd_admin start -name CPFEEDMAN -path /opt/cpfeedman/cpfeedman -command "/opt/cpfeedman/cpfeedman /opt/cpfeedman/.envrc" -slp_timeout 1 -retry_limit u 

watch -d 'cpwd_admin list | grep CPFEEDMAN'

cpwd_admin list | grep CPFEEDMAN
ps ax | grep cpfeedman

tail -f /var/log/cpfeedman.log

cpwd_admin stop -name CPFEEDMAN -path /opt/cpfeedman/cpfeedman -command "/opt/cpfeedman/cpfeedman /opt/cpfeedman/.envrc" 
cpwd_admin del -name CPFEEDMAN

# init.d below

chmdo +x /etc/init.d/cpfeedman

/etc/init.d/cpfeedman
/etc/init.d/cpfeedman status
/etc/init.d/cpfeedman stop
/etc/init.d/cpfeedman start
/etc/init.d/cpfeedman restart
/etc/init.d/cpfeedman status

chkconfig --add cpfeedman
chkconfig cpfeedman on
chkconfig | grep cpfeedman
```

### init.d script

```bash
#!/bin/sh
#
# chkconfig: 345 99 01
# description: CPFEEDMAN watchdog service
# processname: cpfeedman

### BEGIN INIT INFO
# Provides:          cpfeedman
# Required-Start:    $network $local_fs
# Required-Stop:     $network $local_fs
# Default-Start:     3 4 5
# Default-Stop:      0 1 2 6
# Short-Description: CPFEEDMAN Check Point Watchdog service
### END INIT INFO

NAME="CPFEEDMAN"
BIN_PATH="/opt/cpfeedman/cpfeedman"
CMD="$BIN_PATH /opt/cpfeedman/.envrc"

start() {
    echo "Starting $NAME..."
    cpwd_admin start -name $NAME -path $BIN_PATH -command "$CMD" -slp_timeout 1 -retry_limit u
    RETVAL=$?
    [ $RETVAL -eq 0 ] && echo "Started $NAME successfully."
    return $RETVAL
}

stop() {
    echo "Stopping $NAME..."
    cpwd_admin stop -name $NAME -path $BIN_PATH -command "$CMD"
    RETVAL=$?
    [ $RETVAL -eq 0 ] && echo "Stopped $NAME successfully."
    return $RETVAL
}

status() {
    cpwd_admin list | grep $NAME
    RETVAL=$?
    # look for CPFEEDMAN  0      T     0
    # or CPFEEDMAN  <pid>  E     <exec_count>
    RES=$(cpwd_admin list | grep $NAME)
    # check $RES starts with CPFEEDMAN whitespaces <pid> whitespaces E whitespaces <exec_count>
    if [[ $RES =~ ^$NAME[[:space:]]+([0-9]+)[[:space:]]+E[[:space:]]+([0-9]+) ]]; then
        echo "$NAME is running with PID ${BASH_REMATCH[1]} and exec count ${BASH_REMATCH[2]}."
    else
        echo "$NAME is not running."
    fi
    return $RETVAL
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
esac
exit $?
```