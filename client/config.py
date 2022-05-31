
screen_width = 1334  # 屏幕宽度
screen_height = 750  # 屏幕高度

map_width = screen_width*4  # 地图的大小
map_height = screen_height*4  # 地图的大小
number_enemy = map_width*map_height/500000  # 敌人的数量
number_dots = map_width * map_height / 50  # 点点的数量
max_show_size = 100  # 球显示的最大半径（屏幕有限，球再增大时，改变的地图比例尺寸）

my_value = 1000  # 我的初始值
enemy_value_low = 500  # 敌人的初始值（最低）
enemy_value_high = 1500  # 敌人的初始值（最高）
dot_value = 30  # 点点的值（地上的豆豆/食物值）
my_speed = 10  # 我的球运动的速度
speed_up = 20  # 按下鼠标时加速
speed_enemy = 10  # 敌人球正常运动速度
speed_enemy_anomaly = 20  # 敌人突然加速时的速度（速度异常时的速度）
anomaly_pro = 0.5  # 敌人加速的概率
change_pro = 0.05  # 敌人移动路径变化的概率，也就是1/change_pro左右会变化一次
eat_percent = 0.9  # 吃掉敌人的球，按多少比例并入自己的体积，1对应的是100%
loss = 0.001  # 按比例减小体重（此外越重的减少越多，10万体积损失值为loss的一倍）
enemy_bigger_pro = 0.0005  # 敌人的值增加了我的球的值的enemy_bigger_rate倍的几率
enemy_bigger_rate = 0.1  # 增加我的球的体积的enemy_bigger_rate倍

