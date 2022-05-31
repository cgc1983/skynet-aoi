#!/usr/bin/python
# -*- coding: UTF-8 -*-

import pygame
import config
import math
import globalunit

def control_my_ball(host_ball):  # 控制我的球
    host_ball.move()
    host_ball.value = host_ball.value*(1-config.loss*host_ball.value/100000)
    for event in pygame.event.get():  # 监控事件（鼠标移动）
        if event.type == pygame.QUIT:
            print("点击退出")
            globalunit.is_running = False


        if event.type == pygame.MOUSEBUTTONDOWN:
            pos = event.pos
            speed = config.speed_up
        elif event.type == pygame.MOUSEMOTION:
            pos = event.pos
            if event.buttons[0] == 1:
                speed = config.speed_up
            if event.buttons[0] == 0:
                speed = config.my_speed
        elif event.type == pygame.MOUSEBUTTONUP:
            pos = event.pos
            speed = config.my_speed
        else:
            pos = [config.screen_width/2, config.screen_height/2]
            speed = config.my_speed
        if abs(pos[0] - config.screen_width/2) < 30 and abs(pos[1] - config.screen_height/2) < 30:
            host_ball.sx = 0
            host_ball.sy = 0
        elif pos[0] > config.screen_width/2 and pos[1] >= config.screen_height/2:
            angle = abs(math.atan((pos[1] - config.screen_height/2) / (pos[0] - config.screen_width/2)))
            host_ball.sx = int(speed * math.cos(angle))
            host_ball.sy = int(speed * math.sin(angle))
        elif pos[0] > config.screen_width/2 and pos[1] < config.screen_height/2:
            angle = abs(math.atan((pos[1] - config.screen_height/2) / (pos[0] - config.screen_width/2)))
            host_ball.sx = int(speed * math.cos(angle))
            host_ball.sy = -int(speed * math.sin(angle))
        elif pos[0] < config.screen_width/2 and pos[1] >= config.screen_height/2:
            angle = abs(math.atan((pos[1] - config.screen_height/2) / (pos[0] - config.screen_width/2)))
            host_ball.sx = -int(speed * math.cos(angle))
            host_ball.sy = int(speed * math.sin(angle))
        elif pos[0] < config.screen_width/2 and pos[1] < config.screen_height/2:
            angle = abs(math.atan((pos[1] - config.screen_height/2) / (pos[0] - config.screen_width/2)))
            host_ball.sx = -int(speed * math.cos(angle))
            host_ball.sy = -int(speed * math.sin(angle))
        elif pos[0] == config.screen_width/2:
            host_ball.sx = 0
            if pos[1] >= 0:
                host_ball.sy = speed
            else:
                host.ball.sy = -speed