#!/bin/sh
nginx -p `pwd` -c conf/nginx.conf -s stop
rm logs/*.log
nginx -p `pwd` -c conf/nginx.conf
#nginx -p `pwd` -c conf/nginx.conf -s reload
