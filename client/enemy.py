#!/usr/bin/python
# -*- coding: UTF-8 -*-

import pygame
import random
import math
# import numpy as np
from base import Ball
import config
import os
ROOT=os.path.abspath(os.path.dirname(__file__))

class Enemy_Ball(Ball):  # 定义敌人的球，继承了Ball类的方法
    def __init__(self, x, y, sx, sy, color, value, host_ball,id,tp,d):  # 初始化带上host_ball，也就是我的球
        super().__init__(x, y, sx, sy, color, value)
        self.host_ball = host_ball
        self.radius = int(self.value**0.5)
        if self.host_ball.radius >= config.max_show_size:  # 如果我的球比规定的最大尺寸还大，则敌人的球显示的比例要减小
            self.show_radius = max(10, int(self.radius/(self.host_ball.radius/config.max_show_size)))  # 敌人的球也不能太小，最小半径为10
            self.position_x = int((self.x - self.host_ball.x) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_width / 2)  # 计算出敌人的球和我的球的相对位置，并且按比例减小
            self.position_y = int((self.y - self.host_ball.y) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_height / 2)  # 计算出敌人的球和我的球的相对位置，并且按比例减小
        else:
            self.show_radius = self.radius  # 正常显示
            self.position_x = (self.x - self.host_ball.x) + int(config.screen_width / 2)  # 敌人和我的球的相对位置
            self.position_y = (self.y - self.host_ball.y) + int(config.screen_height / 2)  # 敌人和我的球的相对位置

        self.font = pygame.font.Font(os.path.join(ROOT,"resource/simhei.ttf"), 40)
        self.tp = tp
        self.id =id
        self.dir = d

    # 画出球
    def draw(self, window):
        self.radius = int(self.value ** 0.5)
        if self.host_ball.radius >= config.max_show_size:  # 这边把初始化的内容再写一遍，因为敌人的球初始化之后还要根据我的球而动态改变
            self.show_radius = max(10, int(self.radius/(self.host_ball.radius/config.max_show_size)))
            self.position_x = int((self.x - self.host_ball.x) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_width / 2)
            self.position_y = int((self.y - self.host_ball.y) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_height / 2)
        else:
            self.show_radius = self.radius
            self.position_x = (self.x - self.host_ball.x) + int(config.screen_width / 2)
            self.position_y = (self.y - self.host_ball.y) + int(config.screen_height / 2)
        pygame.draw.circle(window, self.color, (self.position_x, self.position_y), self.show_radius)

        c=(255,0,0)
        if self.tp==1:
            c=self.color

        direction="|"
        if self.dir and self.dir>0:
            direction="->"
        elif self.dir and self.dir<0:
            direction="<-"
            pass

        text = self.font.render("{0} ID:{1}".format(direction,self.id), False,c)
        window.blit(text, (self.position_x, self.position_y))

    def eat_ball(self, other):
        if self != other and self.is_alive and other.is_alive:
            distance = ((self.position_x - other.position_x) ** 2 + (self.position_y - other.position_y) ** 2) ** 0.5
            if distance < self.show_radius and (self.show_radius > other.show_radius or (self.show_radius == other.show_radius and self.value > other.value)):
                other.is_alive = False  # 吃球
                self.value += other.value*config.eat_percent
                self.radius = int(self.value ** 0.5)

    def move(self):  # 移动规则
        self.x += self.sx  # 地图位置加上速度
        self.y += self.sy
        # 横向出界
        if self.x < 0:  # 离开了地图左边
            self.sx = -self.sx
            self.x = 0
        if self.x > config.map_width:  # 离开了地图右边
            self.sx = -self.sx
            self.x = config.map_width
        # 纵向出界
        if self.y <= 0:  # 离开了地图下边
            self.sy = -self.sy
            self.y = 0
        if self.y >= config.map_height:  # 离开了地图上边
            self.sy = -self.sy
            self.y = config.map_height

