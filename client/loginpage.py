#!/usr/bin/python
# -*- coding: UTF-8 -*-

import random
import pygame
import config
import config
import os
ROOT=os.path.abspath(os.path.dirname(__file__))

import globalunit
import loginsock

class LoginPage(object):  # 定义球
    def __init__(self):  # 初始化
        self.font = pygame.font.Font(os.path.join(ROOT,"resource/simhei.ttf"), 40)

        # Input box
        self.input_box_user = pygame.Rect(100, 100, 200, 60)
        self.input_box_code = pygame.Rect(100, 300, 200, 60)
        self.text=""
        self.code="123456"
        self.error=""
        self.active1=False
        self.active2=False
        pass


    def loop(self,screen):
        color_background = (0, 0, 0)
        color_inactive = (100, 100, 200)
        color_active = (255, 255, 255)
        color_user = color_inactive
        color_code = color_inactive
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                globalunit.is_running = False
                return

            if event.type == pygame.MOUSEBUTTONDOWN:
                self.active1 = True if self.input_box_user.collidepoint(event.pos) else False
                self.active2 = True if self.input_box_code.collidepoint(event.pos) else False
                pass

            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RETURN:
                    # self.text = ""
                    if self.text!="" and self.code!="":

                        globalunit.user=self.text
                        globalunit.code=self.code
                        # globalunit.status=2
                        loginsock.login()
                        if globalunit.subid:
                            self.error=""
                            globalunit.status=2
                        else:
                            self.error="code错误登录失败"
                            pass
                        pass
                else:
                    if self.active1:
                        if event.key == pygame.K_BACKSPACE:
                            self.text = self.text[:-1]
                        else:
                            self.text += event.unicode
                        pass
                    if self.active2:
                        if event.key == pygame.K_BACKSPACE:
                            self.code = self.code[:-1]
                        else:
                            self.code += event.unicode
                        pass

        # Change the current color of the input box
        color_user = color_active if self.active1 else color_inactive
        # Change the current color of the input box
        color_code = color_active if self.active2 else color_inactive
        # Input box
        text_surface = self.font.render(self.text, True, color_user)
        input_box_user_width = max(200, text_surface.get_width()+10)
        self.input_box_user.w = input_box_user_width
        self.input_box_user.center = (config.screen_width/2, config.screen_height/2)

        # Input box
        code_surface = self.font.render(self.code, True, color_code)
        input_box_code_width = max(200, code_surface.get_width()+10)
        self.input_box_code.w = input_box_code_width
        self.input_box_code.center = (config.screen_width/2, config.screen_height/2+120)


        # Updates
        screen.fill(color_background)

        text = self.font.render(self.error, False,(255,0,0))
        screen.blit(text, (config.screen_width/2, 0))

        text = self.font.render('账号:', False,color_user)
        screen.blit(text, (config.screen_width/2-100, config.screen_height/2-100))
        screen.blit(text_surface, (self.input_box_user.x, self.input_box_user.y))
        pygame.draw.rect(screen, color_user, self.input_box_user, 3)


        text = self.font.render('code:', False, color_code)
        screen.blit(text, (config.screen_width/2-100, config.screen_height/2+40))
        screen.blit(code_surface, (self.input_box_code.x, self.input_box_code.y))
        pygame.draw.rect(screen, color_code, self.input_box_code, 3)

        pygame.display.flip()
        pass
