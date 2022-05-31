# skynet-aoi

skynet lua aoi 演示项目



本文参照了的项目如下



云风的AOI 项目 [GitHub - cloudwu/aoi: Area of Interest Library](https://github.com/cloudwu/aoi)

小风的项目 [GitHub - cloudfreexiao/skynet-aoi: skynet aoi](https://github.com/cloudfreexiao/skynet-aoi)



## 安装

项目依赖openresty和skynet



### 安装OpenResty

下载openresty

```bash
wget https://openresty.org/download/openresty-1.19.9.1.tar.gz
```

解压缩

```bash
tar -zxvf openresty-1.19.9.1.tar.gz
```

编译

```bash
cd openresty-1.19.9.1 && make && make install
```



配置环境变量

```bash
echo "PATH=/usr/local/openresty/nginx/sbin:$PATH
export PATH" >> ~/.bash_profile
```



### 编译skynet

安装依赖

```bash
apt-get install readline-dev autoconf
```



到skynet目录下编译

```bash
make linux
```



### 安装客户端

安装pipenv环境

client目录下执行

```bash
pipenv install
```



## 启动

启动apiserver，到apiserver目录下执行

```bash
./run.sh
```



启动gate,到gate目录下执行

```bash
./run.sh
```



启动skynet，到gameserver目录下执行

```bash
./run.sh
```



启动测试客户端

```bash
pipenv shell && python main.py
```



添加机器人

```bash
nc 127.0.0.1 8000
start aoitest 10001 12000
```
