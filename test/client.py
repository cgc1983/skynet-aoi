#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os
import sys
import websocket
import json
import msgpack
import click


# websocket.enableTrace(True)
serv=None
subid=None
token=None
u=None
pwd=None

X=1
Y=1
SPEED_X=None
SPEED_Y=None
LOGIN_OK=False

def send(wsapp,cmd):
    print("<=======================",cmd)
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
    global u,serv,pwd
    print("on open")
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    cmd={"c":"login","m":"login","data":{"user":u,"password":pwd,"server":serv}}
    # wsapp.send(json.dumps(cmd),websocket.ABNF.OPCODE_BINARY)
    wsapp.send(msgpack.packb(cmd),websocket.ABNF.OPCODE_BINARY)
    pass

def on_login_ping(wsapp, message):
    # print("on ping")
    wsapp.send("ping", websocket.ABNF.OPCODE_PONG)
    pass

def on_login_pong(wsapp, message):
    # print("on_pong")
    pass

def on_login_message(wsapp,message):
    global u,serv,pwd,subid,token
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # print(message)
    cmd=msgpack.unpackb(message)
    print(cmd)
    token=cmd["data"]["token"]
    subid=cmd["data"]["subid"]
    pass

def on_game_open(wsapp):
    global u,serv,pwd,subid,token
    print("游戏服务器连接成功")
    # # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # cmd={"c":"login","m":"login","data":{"user":u,"password":pwd,"server":serv}}
    # # wsapp.send(json.dumps(cmd),websocket.ABNF.OPCODE_BINARY)
    # wsapp.send(msgpack.packb(cmd),websocket.ABNF.OPCODE_BINARY)
    data={
        "id":u,
        "subid":subid,
        "token":token,
    }

    cmd={"c":"user","m":"login","data":data}
    send(wsapp,cmd)
    print("开始登录到游戏服务器")
    pass

def on_game_pong(wsapp, message):
    global X,Y,LOGIN_OK,SPEED_X,SPEED_Y


    if LOGIN_OK:
        X+=SPEED_X
        Y+=SPEED_Y
        data={
            "pos":{
                "x":X,
                "y":Y,
                "z":0,
            }
        }

        cmd={"c":"mainscene","m":"move","data":data}
        send(wsapp,cmd)
        pass
    else:
        data={
            "LOGIN_OK":LOGIN_OK,
        }

        cmd={"c":"heartbeat","m":"ping","data":data}
        send(wsapp,cmd)
        pass
    pass

def on_game_close(wsapp, close_status_code, close_msg):
    # Because on_close was triggered, we know the opcode = 8
    print("游戏服务器断开连接 args:",close_status_code,",close_msg=",close_msg)
    if close_status_code or close_msg:
        print("close status code: " + str(close_status_code))
        print("close message: " + str(close_msg))

    pass


def on_game_message(wsapp,message):
    global X,Y,LOGIN_OK
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
    # print(message)
    cmd=msgpack.unpackb(message)
    print("=======================>",cmd)
    c=cmd["c"]
    m=cmd["m"]
    if c=='user' and m=='login':
        data={
        }

        cmd={"c":"user","m":"loadcontext","data":data}
        send(wsapp,cmd)
        pass
    elif c=='user' and m=='loadcontext':
        LOGIN_OK=True
        data={
            "pos":{
                "x":X,
                "y":Y,
                "z":0,
            }
        }

        cmd={"c":"mainscene","m":"move","data":data}
        send(wsapp,cmd)
        pass
    elif c=='user' and m=='move':
        pass
    pass

@click.command()
@click.option('--server', default="sample", help='服务器的编号')
@click.option('--user', prompt='Your name', help='The person to login.')
@click.option('--password', default="123456", help='默认密码')
@click.option('--x', prompt='输入x坐标', help='x坐标')
@click.option('--y', prompt='输入y坐标', help='y坐标')
@click.option('--speedx', prompt='输入x移动速度', help='x移动速度')
@click.option('--speedy', prompt='输入y移动速度', help='y移动速度')
def client(server,user,password,x,y,speedx,speedy):
    global u,serv,pwd,token,X,Y,SPEED_X,SPEED_Y
    serv=server
    u=user
    pwd = password
    X=int(x)
    Y=int(y)
    SPEED_X=int(speedx)
    SPEED_Y=int(speedy)
    wsapp = websocket.WebSocketApp("ws://127.0.0.1:8866/login", on_open=on_login_open, on_close=on_login_close,on_message=on_login_message,on_ping=on_login_ping,on_pong=on_login_pong)
    wsapp.run_forever(ping_interval=5, ping_timeout=3, ping_payload="ping")

    if token:
        print("开始连接游戏服务器")
        wsapp = websocket.WebSocketApp("ws://127.0.0.1:8866/game", on_open=on_game_open, on_close=on_game_close,on_message=on_game_message,on_ping=on_login_ping,on_pong=on_game_pong)
        wsapp.run_forever(ping_interval=5, ping_timeout=3, ping_payload="ping")
    pass


if __name__ == '__main__':
    client()







