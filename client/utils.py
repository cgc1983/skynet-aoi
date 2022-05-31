#!/usr/bin/python
# -*- coding: UTF-8 -*-

import pygame
import random
import math
# import numpy as np
from config import *

from base import Ball,Color,Dot_Ball
from enemy import Enemy_Ball
from hero import My_Ball
import random
import copy

import requests
import globalunit


def convert2colors(i):
    b =  i & 255
    g = (i >> 8) & 255
    r =   (i >> 16) & 255
    return b,g,r

def loadgate():
    r=requests.get(globalunit.GATE_URL)
    resp=r.json()
    globalunit.server_status = resp["data"]['status']
    globalunit.LOGIN_SERVER = resp["data"]['ws']["login"]
    globalunit.GAME_SERVER = resp["data"]['ws']["game"]
    pass

def creat_my_ball(x,y):  # 产生我的球
    # x = random.randint(0, map_width)  # 我的球在地图中的位置，随机生成
    # y = random.randint(0, map_height)
    # x=0
    # y=0
    value = my_value  # 我的球的初始值
    color = 255, 255, 255  # 我的球的颜色
    sx = 0  # 速度默认为0
    sy = 0
    host_ball = My_Ball(x, y, sx, sy, color, value)  # 调用My_Ball类
    return host_ball  # 返回我的球


def paint(host_ball, balls, dots, screen):
    screen.fill((0, 0, 0))  # 刷漆
    if host_ball.is_alive:
        host_ball.draw(screen)

    balls_copy = copy.copy(balls)
    for k,enemy in balls_copy.items():  # 遍历容器
        if enemy.is_alive:
            enemy.draw(screen)
        else:
            balls.remove(enemy)
    for food in dots:  # 遍历容器
        if food.is_alive:
            food.draw(screen)
        else:
            dots.remove(food)

    pass #end paint


def enemy_move(balls, host_ball):  # 敌人移动
    for enemy in balls:
        enemy.move()  # 移动
        enemy.value = enemy.value*(1-loss*enemy.value/100000)
        if random.randint(1, int(1/enemy_bigger_pro)) == 1:
            enemy.value += host_ball.value*enemy_bigger_rate
        if random.randint(1, int(1/anomaly_pro)) == 1:
            speed_enemy0 = speed_enemy_anomaly  # 敌人异常速度
        else:
            speed_enemy0 = speed_enemy  # 敌人正常速度
        i = random.randint(1, int(1/change_pro))  # 一定的概率改变轨迹
        if i == 1:
            enemy.sx = random.randint(-speed_enemy0, speed_enemy0)
            i2 = random.randint(0, 1)
            if i2 == 0:
                enemy.sy = int((speed_enemy0 ** 2 - enemy.sx ** 2) ** 0.5)
            else:
                enemy.sy = -int((speed_enemy0 ** 2 - enemy.sx ** 2) ** 0.5)

    pass #end enemy_move


def eat_each_other(host_ball, balls, dots):  # 吃球
    for enemy in balls:
        for enemy2 in balls:
            enemy.eat_ball(enemy2)  # 敌人互吃
        for food in dots:
            enemy.eat_ball(food)  # 敌人吃点点
    for enemy in balls:
        host_ball.eat_ball(enemy)  # 我吃敌人
        enemy.eat_ball(host_ball)  # 敌人吃我
    for food in dots:
        host_ball.eat_ball(food)  # 我吃点点
    pass


def auto_creat_ball(balls, host_ball):  # 自动产生敌人的球
    if len(balls) <= number_enemy:  # 控制敌人的数量，如果个数够了，就不再生成
        x = random.randint(0, map_width)  # 敌人球在地图中的位置，随机生成
        y = random.randint(0, map_height)
        value = random.randint(enemy_value_low, enemy_value_high)  # 敌人的球初始值
        sx = random.randint(-speed_enemy, speed_enemy)  # 敌人的球移动速度
        i2 = random.randint(0, 1)  # y的移动方向
        if i2 == 0:
            sy = int((speed_enemy**2 - sx**2) ** 0.5)
        else:
            sy = -int((speed_enemy ** 2 - sx ** 2) ** 0.5)
        color = Color.random_color()  # 敌人的颜色随机生成
        enemy = Enemy_Ball(x, y, sx, sy, color, value, host_ball)
        balls.append(enemy)
        pass

    pass


def create_enemy(host_ball,x,y,id,tp,color,d):
    # x = random.randint(0, map_width)  # 敌人球在地图中的位置，随机生成
    # y = random.randint(0, map_height)
    # value = random.randint(enemy_value_low, enemy_value_high)  # 敌人的球初始值
    # sx = random.randint(-speed_enemy, speed_enemy)  # 敌人的球移动速度
    # i2 = random.randint(0, 1)  # y的移动方向
    # if i2 == 0:
    #     sy = int((speed_enemy**2 - sx**2) ** 0.5)
    # else:
    #     sy = -int((speed_enemy ** 2 - sx ** 2) ** 0.5)
    # color = Color.random_color()  # 敌人的颜色随机生成
    if not color:
        color = 255, 255, 255  # 我的球的颜色
        pass
    # value = random.randint(enemy_value_low, enemy_value_high)  # 敌人的球初始值
    value = 1000
    enemy = Enemy_Ball(x, y, 0, 0, color, value, host_ball,id,tp,d)
    return enemy


def auto_creat_dots(dots, host_ball):  # 自动生成点点
    if len(dots) <= number_dots:  # 控制点点的数量
        x = random.randint(0, map_width)  # 随机生成点点的位置
        y = random.randint(0, map_height)
        value = dot_value  # 点点的值
        sx = 0  # 点点速度为0
        sy = 0
        color = Color.random_color()  # 颜色
        dot = Dot_Ball(x, y, sx, sy, color, value, host_ball)
        dots.append(dot)


def auto_creat_dots(dots, host_ball):  # 自动生成点点
    if len(dots) <= number_dots:  # 控制点点的数量
        x = random.randint(0, map_width)  # 随机生成点点的位置
        y = random.randint(0, map_height)
        value = dot_value  # 点点的值
        sx = 0  # 点点速度为0
        sy = 0
        color = Color.random_color()  # 颜色
        dot = Dot_Ball(x, y, sx, sy, color, value, host_ball)
        dots.append(dot)
