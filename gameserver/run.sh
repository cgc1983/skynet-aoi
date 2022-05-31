#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)

echo $ROOT
export DAEMON=false


if [ ! -d "log" ]; then
  mkdir log
fi

if [[ `uname` == 'Darwin' ]]; then
    if [ $(ps -e -u ${USER} | grep -v grep | grep $(pwd) | grep skynet | wc -l) != 0 ]
    then
        echo "server is already running, please execute ./stop.sh"
    else

    cd $ROOT/../skynet
    ./skynet $ROOT/config
    fi
else
    if [ $(ps e -u ${USER} | grep -v grep | grep $(pwd) | grep skynet | wc -l) != 0 ]
    then
        echo "server is already running, please execute ./stop.sh"
    else

    cd $ROOT/../skynet
    ./skynet $ROOT/config
    fi
fi

