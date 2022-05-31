#!/usr/bin/python
# -*- coding: UTF-8 -*-

"""
This code is supported by the website: https://www.guanjihuan.com
The newest version of this code is on the web page: https://www.guanjihuan.com/archives/703
"""

import pygame
import random
import math
# import numpy as np
from config import *

from base import Ball,Color,Dot_Ball
import utils

from enemy import Enemy_Ball
from hero import My_Ball
import ctrl
from loginpage import LoginPage
from gamepage import GamePage
import globalunit

pageLogin = None
pageGame = None

utils.loadgate()
print(globalunit.LOGIN_SERVER)
print(globalunit.GAME_SERVER)

def main():
    global pageLogin,pageGame
    pygame.init()  # 初始化
    screen = pygame.display.set_mode((screen_width, screen_height))  # 设置屏幕
    pygame.display.set_caption("AOI测试")  # 设置屏幕标题

    while globalunit.is_running:
        if globalunit.status==1:
            #登录页面
            if not pageLogin:
                pageLogin=LoginPage()
                pass
            pageLogin.loop(screen)
            pass
        else:
            if not pageGame:
                pageGame=GamePage()
                pageGame.connect()
                pass

            pageGame.loop(screen)
            # balls = []  # 定义一容器  存放所有的敌方球
            # dots = []  # 定义一容器 存放所有的点点
            # is_running = True  # 默认运行状态
            # host_ball = utils.creat_my_ball()  # 产生我的球
            # i00 = 0  # 一个参数
            # while is_running:
            #     for event in pygame.event.get():
            #         if event.type == pygame.QUIT:
            #             is_running = False
            #     # utils.auto_creat_dots(dots, host_ball)  # 自动生成点点
            #     utils.auto_creat_ball(balls, host_ball)  # 自动生成敌人
            #     utils.paint(host_ball, balls, dots, screen)  # 把所有的都画出来 调用draw方法
            #     pygame.display.flip()  # 渲染
            #     pygame.time.delay(30)  # 设置动画的时间延迟

            #     ctrl.control_my_ball(host_ball)  # 移动我的球
            #     utils.enemy_move(balls, host_ball)  # 敌人的球随机运动
            #     # utils.eat_each_other(host_ball, balls, dots)  # 吃球 调用eat_ball方法
            #     i00 += 1
            #     if np.mod(i00, 50) == 0:
            #         print(host_ball.value)
            pass

if __name__ == '__main__':
    main()
