#!/usr/bin/python
# -*- coding: UTF-8 -*-

import globalunit

import os
import sys
import websocket
import json
import msgpack

def send(wsapp,cmd):
    # print("<=======================",cmd)
    wsapp.send(msgpack.packb(cmd),websocket.ABNF.OPCODE_BINARY)
    pass

def on_login_close(wsapp, close_status_code, close_msg):
    # Because on_close was triggered, we know the opcode = 8
    print("登录服务器断开连接 args:",close_status_code,",close_msg=",close_msg)
    if close_status_code or close_msg:
        print("close status code: " + str(close_status_code))
        print("close message: " + str(close_msg))

    pass

def on_login_open(wsapp):
    print("登录服务器连接成功")
    print("on open")
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    cmd={"c":"login","m":"login","data":{"user":globalunit.user,"password":globalunit.code,"server":globalunit.serv}}
    # wsapp.send(json.dumps(cmd),websocket.ABNF.OPCODE_BINARY)
    # wsapp.send(msgpack.packb(cmd),websocket.ABNF.OPCODE_BINARY)
    send(wsapp,cmd)
    pass

def on_login_ping(wsapp, message):
    # print("on ping")
    wsapp.send("ping", websocket.ABNF.OPCODE_PONG)
    pass

def on_login_pong(wsapp, message):
    # print("on_pong")
    pass

def on_login_message(wsapp,message):
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # print(message)
    cmd=msgpack.unpackb(message)
    # print("====================>",cmd)
    globalunit.token=cmd["data"]["token"]
    globalunit.subid=cmd["data"]["subid"]
    pass

def login():
    wsapp = websocket.WebSocketApp(globalunit.LOGIN_SERVER, on_open=on_login_open, on_close=on_login_close,on_message=on_login_message,on_ping=on_login_ping,on_pong=on_login_pong)
    wsapp.run_forever(ping_interval=5, ping_timeout=3, ping_payload="ping")
    pass