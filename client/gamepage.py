#!/usr/bin/python
# -*- coding: UTF-8 -*-

import random
import pygame
import config
import config
import utils
import ctrl
import os
ROOT=os.path.abspath(os.path.dirname(__file__))

import globalunit
import loginsock
import _thread

from colorama import Fore, Back, Style

import sys
import websocket
import json
import msgpack
import time

from base import Ball,Color,Dot_Ball

MYEVENT01 = pygame.USEREVENT + 1

class GamePage(object):  # 定义球
    def __init__(self):  # 初始化
        self.font = pygame.font.Font(os.path.join(ROOT,"resource/simhei.ttf"), 40)
        self.balls = {}  # 定义一容器  存放所有的敌方球
        self.dots = []  # 定义一容器 存放所有的点点
        self.host_ball = utils.creat_my_ball(1500,1500)  # 产生我的球
        self.login_ok=False
        color = Color.random_color()  # 颜色
        # dot = Dot_Ball(100, 100, 0, 0, color, 5, self.host_ball)
        # self.dots.append(dot)
        # dot = Dot_Ball(110, 100, 0, 0, color, 5, self.host_ball)
        # self.dots.append(dot)
        self.clock = pygame.time.Clock()
        self.lasttime = int(time.time()*1000)
        self.enemy_map={}
        pass


    def connect2server(self):
        self.wsapp.run_forever(ping_interval=5, ping_timeout=3, ping_payload="ping")
        pass


    def send(self,cmd):
        # print("<=======================",cmd)
        self.wsapp.send(msgpack.packb(cmd),websocket.ABNF.OPCODE_BINARY)
        pass
    def sendpos(self):
        if not self.login_ok:return
        data={
            "pos":{
                "x":self.host_ball.x,
                "y":self.host_ball.y,
                "z":0,
            }
        }

        cmd={"c":"mainscene","m":"move","data":data}
        self.send(cmd)
        pass

    def connect(self):
        def on_game_ping(wsapp, message):
            wsapp.send("pong", websocket.ABNF.OPCODE_PONG)
            pass

        def on_game_pong(wsapp, message):
            # print("on_pong")
            pass

        def on_game_message(wsapp, message):
            cmd=msgpack.unpackb(message)
            c=cmd["c"]
            m=cmd["m"]

            # print("c=",c,",m=",m,",cmd=",cmd)
             # {'m': 'updateaoiobj', 'data': {'errcode': 0, 'obj': {'movement': {'mode': 'wm', 'pos': {'z': 0, 'y': 10, 'x': 10}}, 'type': 2, 'agent': 16777244, 'tempid': 100}}, 'c': 'aoi'}
            if c=='user' and m=='login':
                self.login_ok=True
                # print("登录=======================",self.login_ok)
                pass
            elif c=='aoi':
                if m=='addaoiobj':
                    # print("c=",c,",m=",m)
                    tempid=cmd["data"]["obj"]["tempid"]
                    movement=cmd['data']['obj']['movement']
                    tp=cmd['data']['obj']['type']

                    if not tempid in self.balls:
                        if m=="updateaoiobj":
                            print(Fore.RED+"没有addaoiobj tempid=",tempid)
                            print(Style.RESET_ALL)
                        else:
                            reason = cmd["data"]["reason"]
                            print(Fore.GREEN+"单个addaoiobj tempid=",tempid,",reason=",reason)
                            print(Style.RESET_ALL)
                        c=None
                        if "colors" in cmd['data']['obj']:
                            c=cmd['data']['obj']['colors']
                            pass

                        d=None
                        if "dir" in cmd['data']['obj']:
                            d=cmd['data']['obj']["dir"]
                            pass

                        # print("d===",d)
                        self.balls[tempid]=utils.create_enemy(self.host_ball,movement["pos"]["x"],movement["pos"]["y"],tempid,tp,c,d)
                        pass
                elif m== "updateaoiobj":
                    tempid=cmd["data"]["obj"]["tempid"]
                    movement=cmd['data']['obj']['movement']
                    tp=cmd['data']['obj']['type']

                    if tempid in self.balls:
                        # print("  found ====================>",c,m,self.balls[tempid])
                        # print("当前位置",movement)
                        self.balls[tempid].x=movement["pos"]["x"]
                        self.balls[tempid].y=movement["pos"]["y"]

                        if "dir" in cmd['data']["obj"]:
                            self.balls[tempid].dir=cmd['data']["obj"]["dir"]
                            pass
                        # print("move ball-->",movement)
                        pass
                    else:
                        # print("move ball not found -->",movement)
                        pass
                    pass
                elif m== "updateaoilist":
                    print("updateaoilist====>",cmd["data"])
                    enterlist=cmd["data"]["enterlist"]
                    leavelist=cmd["data"]["leavelist"]

                    list1=enterlist["playerlist"]+enterlist["monsterlist"]
                    print("list1=",list1)
                    print("list1 length:",len(list1))
                    for obj in list1:
                        print("obj===>",obj)
                        tempid=obj["tempid"]
                        movement=obj['movement']
                        tp=obj['type']
                        print(Fore.GREEN+"同步addaoiobj tempid=",tempid)
                        print(Style.RESET_ALL)
                        if not tempid in self.balls:
                            # print(" not found ====================>",c,m,movement,tempid)
                            c=None
                            if "colors" in cmd['data']['obj']:
                                c=cmd['data']['obj']['colors']
                                pass

                            d=None
                            if "dir" in obj:
                                d=obj["dir"]
                                pass
                            self.balls[tempid]=utils.create_enemy(self.host_ball,movement["pos"]["x"],movement["pos"]["y"],tempid,tp,c,d)
                            pass
                        pass

                    list2=leavelist["playerlist"]+leavelist["monsterlist"]
                    print("list2=",list2)
                    for obj in list2:
                        print("obj===>",obj)
                        tempid=obj["tempid"]
                        print(Fore.YELLOW+"同步删除=",tempid)
                        print(Style.RESET_ALL)
                        if tempid in self.balls:
                            del self.balls[tempid]
                            
                            pass
                        pass
                    pass
                elif m=="delaoiobj":
                    tempid=cmd['data']['tempid']
                    reason=cmd['data']['reason']
                    print(Fore.YELLOW+"直接删除={}, reason={}".format(tempid,reason))
                    print(Style.RESET_ALL)
                    if tempid in self.balls:
                        del self.balls[tempid]
                        pass
                    pass
                    # print("敌人个数为:",len(self.balls.keys()))
                pass
            pass

        def on_game_close(wsapp, close_status_code, close_msg):
            # Because on_close was triggered, we know the opcode = 8
            print("游戏服务器断开连接 args:",close_status_code,",close_msg=",close_msg)
            if close_status_code or close_msg:
                print("close status code: " + str(close_status_code))
                print("close message: " + str(close_msg))

            pass
        def on_game_open(wsapp):
            print("游戏服务器连接成功")
            # # wsapp.send("Hello",websocket.ABNF.OPCODE_BINARY)
            # cmd={"c":"login","m":"login","data":{"user":u,"password":pwd,"server":serv}}
            # # wsapp.send(json.dumps(cmd),websocket.ABNF.OPCODE_BINARY)
            # wsapp.send(msgpack.packb(cmd),websocket.ABNF.OPCODE_BINARY)
            data={
                "id":globalunit.user,
                "subid":globalunit.subid,
                "token":globalunit.token,
            }

            cmd={"c":"user","m":"login","data":data}
            self.send(cmd)
            print("开始登录到游戏服务器")
            pass

        wsapp = websocket.WebSocketApp(globalunit.GAME_SERVER, on_open=on_game_open, on_close=on_game_close,on_message=on_game_message,on_ping=on_game_ping,on_pong=on_game_pong)
        self.wsapp = wsapp
        _thread.start_new_thread( self.connect2server,())
        pass

    def loop(self,screen):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                globalunit.is_running = False
        # utils.auto_creat_dots(self.dots, self.host_ball)  # 自动生成点点
        # utils.auto_creat_ball(self.balls, self.host_ball)  # 自动生成敌人
        utils.paint(self.host_ball, self.balls, self.dots, screen)  # 把所有的都画出来 调用draw方法
        passed_time = self.clock.tick()
        if passed_time <=0 :
                passed_time = 1
        fps =  int(1/passed_time*1000)

        text = self.font.render("FPS:{}".format(fps), False,(255,0,0))
        screen.blit(text, (config.screen_width/2, 0))


        pygame.display.flip()  # 渲染
        pygame.time.delay(30)  # 设置动画的时间延迟

        ctrl.control_my_ball(self.host_ball)  # 移动我的球
        self.sendpos()
        # n=int(time.time()*1000)
        # if (n-self.lasttime)>100:
        #     self.lasttime = n
        #     pass
        # utils.enemy_move(self.balls, self.host_ball)  # 敌人的球随机运动
        pass