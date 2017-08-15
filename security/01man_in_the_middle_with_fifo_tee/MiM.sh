#!/usr/bin/env bash
fifo=$(mktemp -u)
mkfifo ${fifo}

cleanup() {
    rm -fv ${fifo}
    pkill -e -f "python -m SimpleHTTPServer ${srv_port}"
}

change_stuff() {
    while read i; do
        echo "${i}" | sed 's/hello world/foo bar baz/'
    done
}

intercept_port="1234"
srv_port="8000"
to_log="to.log"
from_log="from.log"
changed_log="changed.log"
webserver_log="webserver.log"
>${to_log}
>${from_log}
>${changed_log}
trap "cleanup" EXIT

echo "Starting Web Server"
python -m SimpleHTTPServer ${srv_port} 2>&1 | tee ${webserver_log} &
sleep 2
webserver_pid=$!

echo "Send traffic to: localhost:${intercept_port}"
while true; do
    # | change_stuff \
    cat ${fifo} \
        | nc -v -l -p ${intercept_port} \
        | tee -a ${to_log} \
        | nc 127.0.0.1 ${srv_port} \
        | tee -a ${from_log} \
        | tee -a ${changed_log} > ${fifo} 
done
