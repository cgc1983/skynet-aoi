#!/usr/bin/python
# -*- coding: UTF-8 -*-

import pygame
import random
import math
# import numpy as np
from config import *
from base import Ball
import os

ROOT=os.path.abspath(os.path.dirname(__file__))

class My_Ball(Ball):  # 定义我的球，继承了Ball类的方法
    def __init__(self, x, y, sx, sy, color, value):
        # 注意：如果重写了__init__() 时，实例化子类，就不会调用父类已经定义的__init__()
        # 如果子类不重写__init__()方法，实例化子类后，会自动调用父类的__init__()的方法
        # 如果子类重写__init__()方法又需要调用父类的方法，则要使用super关键词。
        super().__init__(x, y, sx, sy, color, value)  # 调用父类Ball的初始化方法__init__()
        self.radius = int(self.value**0.5)  # 我的球的半径（不考虑系数pi）
        if self.radius >= max_show_size:  # 如果半径比规定的最大半径还大，则显示最大半径
            self.show_radius = max_show_size  # 我的球显示的半径
        else:
            self.show_radius = self.radius  # 如果半径没有超过规定最大的半径，则显示原来实际大小的半径
        self.position_x = int(screen_width/2)   # 把我的球固定在屏幕中间position_x，是屏幕显示的位置
        self.position_y = int(screen_height/2)  # 把我的球固定在屏幕中间position_y，是屏幕显示的位置
        self.font = pygame.font.Font(os.path.join(ROOT,"resource/simhei.ttf"), 40)

    def draw(self, window):  # 把我的球画出来
        self.radius = int(self.value ** 0.5)   # 这里重复上面的，因为除了初始化之后，还要更新
        if self.radius >= max_show_size:
            self.show_radius = max_show_size
        else:
            self.show_radius = self.radius
        self.position_x = int(screen_width / 2)
        self.position_y = int(screen_height / 2)
        pygame.draw.circle(window, self.color, (self.position_x , self.position_y), self.show_radius)
        surface = self.font.render("x={0},y={1}".format(self.x,self.y),False,(255,255,255))
        window.blit(surface,(self.position_x , self.position_y))
        pass

    def eat_ball(self, other):  # 吃别的球（包括小点点和敌人）
        if self != other and self.is_alive and other.is_alive:  # 如果other不是自身，自身和对方也都是存活状态，则执行下面动作
            distance = ((self.position_x - other.position_x) ** 2 + (self.position_y - other.position_y) ** 2) ** 0.5   # 两个球之间的距离
            if distance < self.show_radius and (self.show_radius > other.show_radius or (self.show_radius == other.show_radius and self.value > other.value)):  # 如果自身半径比别人大，而且两者距离小于自身半径，那么可以吃掉。
                other.is_alive = False  # 吃球（敌方已死）
                self.value += other.value*eat_percent   # 自己的值增大（体量增大）
                self.radius = int(self.value ** 0.5)  # 计算出半径
                if self.radius >= max_show_size:  # 我的球的显示半径
                    self.show_radius = max_show_size
                else:
                    self.show_radius = self.radius

    def move(self):  # 移动规则
        self.x += self.sx  # 地图位置加上速度
        self.y += self.sy
        # 横向出界
        if self.x < 0:  # 离开了地图左边
            self.x = 0
        if self.x > map_width:  # 离开了地图右边
            self.x = map_width
        # 纵向出界
        if self.y <= 0:  # 离开了地图下边
            self.y = 0
        if self.y >= map_height:  # 离开了地图上边
            self.y = map_height

