#!/bin/bash

set -eu

NAME="newsms"
INIT_SCRIPT=/etc/init.d/$NAME
LOGROTATE_CONF=/etc/logrotate.d/$NAME
BASE_FOLDER=/opt/$NAME

# if $BASE_FOLDER missing create it
if [ ! -d $BASE_FOLDER ]; then
    mkdir -p $BASE_FOLDER
fi

echo "Check list $INIT_SCRIPT $LOGROTATE_CONF"

if [ -f $INIT_SCRIPT ]; then
    echo "Init script already exists. CANCELING INSTALLATION"
    exit 1
fi

if [ -f $LOGROTATE_CONF ]; then
    echo "Logrotate config already exists. CANCELING INSTALLATION"
    exit 1
fi

cat << 'EOF' > $INIT_SCRIPT
#!/bin/sh
#
# chkconfig: 345 99 01
# description: NEWSMS watchdog service
# processname: newsms

### BEGIN INIT INFO
# Provides:          newsms
# Required-Start:    $network $local_fs
# Required-Stop:     $network $local_fs
# Default-Start:     3 4 5
# Default-Stop:      0 1 2 6
# Short-Description: NEWSMS Check Point Watchdog service
### END INIT INFO

# Load Check Point environment
if [ -f /etc/profile.d/CP.sh ]; then
    . /etc/profile.d/CP.sh
elif [ -f $CPDIR/tmp/.CPprofile.sh ]; then
    . $CPDIR/tmp/.CPprofile.sh
fi

PATH=$CPDIR/bin:$PATH
export PATH

NAME="NEWSMS"
BIN_PATH="/usr/bin/sh"
CMD="/usr/bin/sh -c 'cd /opt/newsms && ./newsms 2>&1 >> /var/log/newsms.log'"

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
EOF


cat << 'EOF' > $LOGROTATE_CONF
/var/log/newsms.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
    size 10M
}
EOF

# cat << 'EOF' > $BASE_FOLDER/start_newsms.sh
# #!/bin/bash
# /opt/newsms/newsms 2>&1 | tee -a /var/log/newsms.log
# EOF

# chmod +x $BASE_FOLDER/start_newsms.sh

cat << 'EOF' > $BASE_FOLDER/newsms.sh
#!/bin/bash

TS=$(date +%s)
echo "[$TS] This is mockup send sms script"
echo "Phone: $NEWSMS_PHONE"
echo "SMSTEXT: $NEWSMS_SMSTEXT"

# run curl_cli to real provider here and use variables $NEWSMS_PHONE and $NEWSMS_SMSTEXT

echo "SMS sent (mockup)"

curl_cli -k -v -m2 -d '{"phone":"'"$NEWSMS_PHONE"'","message":"'"$NEWSMS_SMSTEXT"'"}' \
-u sms:vpn123 -H "Content-Type: application/json" \
https://nanuc-1.buru-gamma.ts.net/webhook/3e462382-59dc-4a38-9b92-1776c441dc45
echo ""


exit 0
EOF

chmod +x $BASE_FOLDER/newsms.sh

chmod +x $INIT_SCRIPT

chkconfig --add newsms
chkconfig newsms on
chkconfig --list newsms

echo "Logrotate config created $LOGROTATE_CONF"
echo "Use $INIT_SCRIPT to start and check status"
echo
echo "Binary: "
echo "cd /opt/newsms; curl_cli -k -OL https://github.com/mkol5222/pub.filex/raw/refs/heads/newsms/newsms; chmod +x ./newsms"
echo