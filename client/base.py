#!/usr/bin/python
# -*- coding: UTF-8 -*-

import random
import pygame
import config

class Ball(object):  # 定义球
    def __init__(self, x, y, sx, sy, color, value):  # 初始化
        self.x = x  # 球的地图位置参数
        self.y = y
        self.sx = sx  # 速度参数
        self.sy = sy
        self.color = color  # 颜色
        self.value = value  # 球的值，也就是球的大小（不是显示的大小）
        self.is_alive = True  # 球默认是存活状态


class Color(object):  # 定义颜色的类
    @classmethod  # 加了这个可以不需要把实例化，能直接调用类的方法
    def random_color(cls):  # cls, 即class，表示可以通过类名直接调用
        red = random.randint(0, 255)
        green = random.randint(0, 255)
        blue = random.randint(0, 255)
        return red, green, blue


class Dot_Ball(Ball):  # 定义地上的小点点，供自己的球和敌人的球吃，继承了Ball类的方法
    def __init__(self, x, y,  sx, sy, color, value, host_ball):
        super().__init__(x, y, sx, sy, color, value)
        self.host_ball = host_ball
        self.radius = 8  # 初始小点点大小
        if self.host_ball.radius >= config.max_show_size:
            self.show_radius = max(3, int(self.radius/(self.host_ball.radius/config.max_show_size)))  # 小点点显示也不能太小，最小显示半径为3
            self.position_x = int((self.x - self.host_ball.x) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_width / 2)
            self.position_y = int((self.y - self.host_ball.y) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_height / 2)
        else:
            self.show_radius = self.radius
            self.position_x = (self.x - self.host_ball.x) + int(config.screen_width / 2)
            self.position_y = (self.y - self.host_ball.y) + int(config.screen_height / 2)

    # 画出球
    def draw(self, window):
        if self.host_ball.radius >= config.max_show_size:  # 这边把初始化的内容再写一遍，因为小点点初始化之后还要根据我的球而动态改变
            self.show_radius = max(3, int(self.radius/(self.host_ball.radius/config.max_show_size)))
            self.position_x = int((self.x - self.host_ball.x) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_width / 2)
            self.position_y = int((self.y - self.host_ball.y) / (self.host_ball.radius / config.max_show_size)) + int(
                config.screen_height / 2)
        else:
            self.show_radius = self.radius
            self.position_x = (self.x - self.host_ball.x) + int(config.screen_width / 2)
            self.position_y = (self.y - self.host_ball.y) + int(config.screen_height / 2)
        pygame.draw.circle(window, self.color, (self.position_x, self.position_y) , self.show_radius)