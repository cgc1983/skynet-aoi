#!/bin/sh
if [[ `uname` == 'Darwin' ]]; then
  PID=$(ps -e -u ${USER} | grep -v grep | grep "$(pwd)" | grep skynet | awk '{print $2}')
else
  PID=$(ps e -u ${USER} | grep -v grep | grep "$(pwd)" | grep skynet | awk '{print $1}')
fi
kill ${PID}