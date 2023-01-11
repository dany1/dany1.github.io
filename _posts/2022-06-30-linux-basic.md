---
layout: post
title: linux基础知识
date:   2022-06-30 10:58:36 +0800
categories: linux
tags:
- linux
---

记录一下linux运维常用到的命令

## 时间同步

### 自建ntpd时间同步原理

1. 服务器启动ntp
2. 客户端会向服务器发送调整时间的消息
3. 服务器会告诉客户端当前标准时间
4. 客户端接收服务器返回的消息,根据信息来调整自己的时间,实现网络对时

校准时间的时候,ntpd有一个自我保护设置,当本机与服务器时间相差太大的时候,ntpd不运行,因为时差太大的时候强制调整,可能会引起其他程序的错误.

## 免密登录

电脑A需要免密登录B,把A的公钥放到B的~/.ssh/authorized_keys, 免密的一般用于需要scp拷贝文件这种场景

```shell
# 先在A电脑通过ssh-keygen生成公钥和私钥,默认生成在~/.ssh/目录下面,公钥是id_rsa.pub  私钥是id_rsa
ssh-keygen
# 把生成的公钥复制到远程的B电脑, 想要用哪个用户登录B电脑,user就填那个
ssh-copy-id user@B
```

## ssh多端口

先要修改sshd配置,然后注意防火墙是否允许新的端口访问

```shell
#编辑 /etc/ssh/sshd_config
sudo vim /etc/ssh/sshd_config
# 要先注释掉Port 5522 然后 添加
# Port 5522
ListenAddress 0.0.0.0:22
ListenAddress 0.0.0.0:5522
# 开启防火墙
sudo iptables -I INPUT -p tcp -m tcp --dport 5522 -j ACCEPT
# 在/etc/sysconfig/iptables加上这句
sudo vim /etc/sysconfig/iptables
-A INPUT -p tcp -m tcp --dport 5522 -j ACCEPT
```

## 用户管理

创建无法ssh的用户

```shell
sudo useradd -g group  -s /sbin/nologin  username
```

## 防火墙开启端口

### fireall
```shell
# 添加  permanent表示永久添加
firewall-cmd --zone=public --add-port=80/tcp --permanent
# 移除
firewall-cmd --zone=public --remove-port=80/tcp --permanent
# 重新加载
firewall-cmd --reload
```

### iptables

添加的规则重启后就失效了,想要规则永久有效,修改`/etc/sysconfig/iptables` 添加相应的规则

```shell
# 在/etc/sysconfig/iptables加上这句
-A INPUT -p tcp -m tcp --dport 9000 -j ACCEPT

# 重启iptables
sudo service iptables restart

# 添加一条规则  /16 表示前16位,匹配所有的172.17开头地址
sudo iptables -I INPUT -p tcp -m tcp --dport 6379 -j ACCEPT
```

### ip地址表示

ip地址后斜杠,是CIDR表示, 比如24表示掩码位是24位的, 即11111111 11111111 11111111 00000000，将其转化为十进制，就是：255.255.255.0,所以192.168.0.0/24 表示从192.168.0.1开始到192.168.0.254结束,子网掩码是255.255.255.0

## gitlab安装

gitlab用docker安装,为了省资源,把nginx外置在宿主机和其他的程序公用, 通过https方式访问,nginx的配置文件有几点要注意,要不然登录的时候会422

```nginx
proxy_set_header X-Forwarded-Ssl on;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_http_version 1.1;
```

重置密码[官网链接](https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password)

```shell
sudo gitlab-rake "gitlab:password:reset"
# 等一段时间之后,根据提示数据账号 修改密码
Enter username: abce
Enter password: 
Confirm password: 
Password successfully updated for user with username abce.
```

备份恢复

```shell
# 创建备份
gitlab-backup create
# 忽略数据库和uploads备份
gitlab-backup create SKIP=db,uploads
# 恢复备份
gitlab-backup restore force=yes BACKUP=1597812374_2020_08_19_12.10.5
```

### centos开机自动联网

```shell
cd /etc/sysconfig/network-scripts
vim  ifccfg-eth0

TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=dhcp
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eth0
UUID=46670905-b22d-46a3-81d4-4a9a3731d9ab
DEVICE=eth0
#修改为yes默认值是no
ONBOOT=yes

```

### 挂载nfs

```shell
# 查看nfs-utils是否安装，没安装的安装一下
rpm -qa | grep nfs-utils
yum install nfs-utils
# 查看可以mount的信息
showmount -e 192.168.1.111
#显示如下信息
Export list for 192.168.1.111:
/volume/data 192.168.1.111
# 挂载
sudo mount -t nfs 192.168.1.111:/volume/data /mnt/data
# 开机自动挂载编辑 /etc/fstab
192.168.1.111:/volume/data /mnt/data nfs defaults 0 0
```


