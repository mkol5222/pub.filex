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
