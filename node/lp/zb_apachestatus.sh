#! /bin/bash
#
# ex
# ./zb_apachestatus.sh --debug --sender=/home/affix/zabbix/bin/zabbix_sender --host=127.0.0.1 --zabbixsource="apache2" --zabbixserver=10.0.1.41
#
# cron
# */5 * * * * zb_apachestatus.sh --debug --sender=/home/affix/zabbix/bin/zabbix_sender --host=127.0.0.1 --zabbixsource="apache2" --zabbixserver=10.0.1.41
#
 
name="zb_apacheStatus"
version="0.4"

# Test  if  your  getopt(1)  is this enhanced version or an old version
getopt --test > /dev/null
if [[ $? != 4 ]]; then
    echo "`getopt --test` failed in this environment."
    exit 1
fi

# Help function
function usage()
{
echo "
$0 $version

Usage: $0 [Options]

This script collect statistics from Apache status page, write to a temporary file
and send using zabbix_sender, the script will do only one request per execution.

License: GPL

Options:
  --version             show version and exit

  -h, --help            show this help page and exit

  -l URL, --url=URL     Define a custom URL to use
                        When you use URL, the options
                        --host, --port, --proto, --user and --passwd are not used
                        [--url=http://localhost/my-server-status?auto]
                        [default: None]

  -o HOST, --host=HOST  Apache host to collect info.
                        [default: localhost]

  -p PORT, --port=PORT  Apache port to collect info
                        [default: 80]

  -r PROTO, --proto=PROTO
                        Protocol to use. [http or https]
                        [default: http]

  --TIMEOUT=seconds     Connection timeout
                        [default: 30]

  -z ZABBIXSERVER, --zabbixserver=ZABBIXSERVER
                        Hostname or IP address of Zabbix server
                        [default: localhost]

  -u USER, --user=USER  HTTP authentication user
                        [default: None]

  -a PASSWD, --passwd=PASSWD
                        HTTP authentication password
                        [default: None]

  -s SENDERLOC, --sender=SENDERLOC
                        Path of zabbix_sender binary
                        [default: /usr/bin/zabbix_sender]

  -q ZABBIXPORT, --zabbixport=ZABBIXPORT
                        Specify port number of Zabbix server
                        trapper running on the server
                        [default: 10051]

  -c ZABBIXSOURCE, --zabbixsource=ZABBIXSOURCE
                        Specify host name the item belongs to
                        (as registered in Zabbix frontend)
                        [default: localhost]

  -k CONFIGFILE, --config=CONFIGFILE
                        Specify the file with the list of statistics to collect
                        [default: run $0 --dumpconfig]

  --dumpconfig          Show the atual config

  -d, --debug           Run using Debug mode

  -t, --test            Do not send data, simply test, use with --debug
"
}

# Define some default values
HOST=localhost
PORT=80
PROTO=http
ZABBIXSERVER=localhost
SENDER=/usr/bin/zabbix_sender
DEBUG=0
TEST=0
ZABBIXPORT=10051
ZABBIXSOURCE=localhost
TIMEOUT=30
DEFAULTCONFIG="ServerVersion
Total Accesses
Total kBytes
CPULoad
CPUSystem
CPUUser
Load1
Load5
Load15
Uptime
ReqPerSec
BytesPerSec
BytesPerReq
BusyWorkers
IdleWorkers
Scoreboard"

# Use getopt(1) program to parse command line options
SHORT=vhl:o:p:r:z:u:a:s:q:c:k:dt
LONG=version,help,url:,host:,port:,proto:,zabbixserver:,user:,passwd:,sender:,zabbixport:,zabbixsource:,config:,timeout:,debug,dumpconfig,test
PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$PARSED"

while true; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            echo "$name $version"
            exit 0
            ;;
        -l|--url)
            URL="$2"
            shift 2
            ;;
        -o|--host)
            HOST="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -r|--proto)
            PROTO="$2"
            if [[ $PROTO != "http" && $PROTO != "https" ]]; then
                usage
                exit 3
            fi
            shift 2
            ;;
        -z|--zabbixserver)
            ZABBIXSERVER="$2"
            shift 2
            ;;
        -u|--user)
            APACHEUSER="$2"
            shift 2
            ;;
        -a|--passwd)
            APACHEPASSWD="$2"
            shift 2
            ;;
        -s|--sender)
            SENDER="$2"
            shift 2
            ;;
        -q|--zabbixport)
            ZABBIXPORT="$2"
            shift 2
            ;;
        -c|--zabbixsource)
            ZABBIXSOURCE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -k|--config)
            CONFIGFILE="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG=1
            shift
            ;;
        --dumpconfig)
            echo "$DEFAULTCONFIG"
            exit 0
            ;;
        -t|--test)
            TEST=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            exit 3
            ;;
    esac
done

# Temporary files
STATUSFILE=`mktemp`
SENDERFILE=`mktemp`
if [[ -z $CONFIGFILE ]]; then
	CONFIGFILE=`mktemp`
	tmpCONFIGFILE=1
	echo "$DEFAULTCONFIG" > $CONFIGFILE
fi

# Build URL to be used
if [[ -n $URL ]]; then
	STATUS_URL=$URL
else
	STATUS_URL="$PROTO://$HOST:$PORT/server-status?auto"
fi

# get data using curl or wget
curl="`which curl`"
if [ "$curl" ]; then
	GET_CMD="$curl --insecure --max-time $TIMEOUT --silent --location -H \"Cache-Control: no-cache\" \"$STATUS_URL\""
	if [[ -n $APACHEUSER && -n $APACHEPASSWD ]]; then
		GET_CMD="${GET_CMD} --user $APACHEUSER:$APACHEPASSWD"
	fi
else
	wget="`which wget`"
	if [ "$wget" ]; then
		GET_CMD="$wget --no-check-certificate --timeout=$TIMEOUT --quiet --header \"Cache-Control: no-cache\" -O - \"$STATUS_URL\""
		if [[ -n $APACHEUSER && -n $APACHEPASSWD ]]; then
			GET_CMD="${GET_CMD} --user=$APACHEUSER --password=$APACHEPASSWD"
		fi
	else
		echo "I can not find curl or wget on your system"
		exit 1
	fi
fi

# get data from server
eval $GET_CMD > $STATUSFILE
RET_VAL=$?

# in case of error, just send [failed] = 1
# otherwise send all collected data
if [[ $RET_VAL = 0 ]]; then
	echo "\"$ZABBIXSOURCE\" \"custom.apache[failed]\" 0" >> $SENDERFILE

	# read the config file to get all relevant statistics
	while read STATNAME
	do
		if [[ $STATNAME = "Scoreboard" ]]; then
			SCOREBOARD=`fgrep -w "$STATNAME:" $STATUSFILE | sed "s/$STATNAME: //"`
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[WaitingForConnection]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"_")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[StartingUp]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"S")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[ReadingRequest]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"R")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[SendingReply]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"W")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[KeepAlive]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"K")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[DNSLookup]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"D")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[ClosingConnection]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"C")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[Logging]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"L")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[GracefullyFinishing]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"G")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[IdleCleanupOfWorker]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"I")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[OpenSlotWithNoCurrentProcess]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,".")}' >> $SENDERFILE
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[TotalWorkers]\" " >> $SENDERFILE
			echo $SCOREBOARD | awk '{print split($1,dummy,"")}' >> $SENDERFILE
		else
			echo -n "\"$ZABBIXSOURCE\" \"custom.apache[$STATNAME]\" " >> $SENDERFILE
			LINE=`fgrep -w "$STATNAME:" $STATUSFILE`
			if [[ $? = 0 ]]; then
				echo $LINE | sed "s/$STATNAME: //" >> $SENDERFILE
			else
				echo 0 >> $SENDERFILE;
			fi
		fi
	done < $CONFIGFILE
else
	echo "\"$ZABBIXSOURCE\" \"custom.apache[failed]\" 1" >> $SENDERFILE
fi

# Send all information to Zabbix using zbbix_sender
SENDER_CMD="$SENDER -v --zabbix-server $ZABBIXSERVER --port $ZABBIXPORT --input-file $SENDERFILE"

# DEBUG
if [[ $DEBUG = 1 ]]; then
	echo -e "\n########################################\n"
	echo -e "Statistics available on your server:\n"
	cat $STATUSFILE | awk -F: '{print $1}'
	
	echo -e "\n########################################\n"
	echo -e "Statistics that I am collecting:\n"
	cat $CONFIGFILE
	
	echo -e "\n########################################\n"
	echo -e "Metrics to be send\n"
	SENDERFILEDEBUG=`mktemp`
	echo '"SERVER" "METRIC" VALUE' >> $SENDERFILEDEBUG
	cat $SENDERFILE >> $SENDERFILEDEBUG
	column -t -s'\"' $SENDERFILEDEBUG
	rm -f $SENDERFILEDEBUG
	
	echo -e "\n########################################\n"
	echo -e "Parameters\n"
	echo "--host=$HOST"
	echo "--port=$PORT"
	echo "--proto=$PROTO"
	echo "--zabbixserver=$ZABBIXSERVER"
	echo "--sender=$SENDER"
	echo "--zabbixport=$ZABBIXPORT"
	echo "--zabbixsource=$ZABBIXSOURCE"
	echo "--url=$URL"
	echo "--user=$APACHEUSER"
	echo "--passwd=$APACHEPASSWD"
	echo "--timeout=$TIMEOUT"
	echo "Final URL: $STATUS_URL"
	
	echo -e "\n########################################\n"
	echo -e "Command line to collect data from Apache\n"
	echo -e "$GET_CMD\n"
	echo -e "Command line to send data to Zabbix\n"
	echo -e "$SENDER_CMD\n"
	
	if [[ $TEST = 0 ]]; then
		echo -e "\n########################################\n"
		echo -e "zabbix_sender output\n"
		eval $SENDER_CMD
		echo -e "\n"
	fi
else
	[[ $TEST = 0 ]] && eval $SENDER_CMD > /dev/null
fi

# Housekeeping
rm -f $STATUSFILE
rm -f $SENDERFILE
if [[ -n $tmpCONFIGFILE ]]; then
	rm -f $CONFIGFILE
fi
