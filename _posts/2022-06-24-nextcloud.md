---
layout: post
title: nextcloud安装
date:   2022-06-24 10:58:36 +0800
categories: nextcloud
tags:
- nextcloud
---

使用家里面的废旧笔记本装个centos 7,然后安装个nextcloud, 作为存放照片,文档的网盘, 记录一下安装过程过程

## lnmp安装

从lnmp.org上下载脚本,安装mysql(8.0.29),php(8.1.7),nginx  
lnmp1.9的脚本要修改一下,要不然无法在centos7(2009)上安装mysql(8.0.29),主要是 centos7(2009)的glibc版本是2.17

```shell
#lnmp.conf设置

#安装完之后mysql的设置
#/etc/my.cnf
character_set_server = UTF8MB4
collation_server = UTF8MB4_GENERAL_CI
#创建账号
create user 'nextcloud'@'localhost' identified with mysql_native_password by 'aaaaa';
grant all privileges nextcloud.* to 'nextcloud'@'localhost' with grant option;
flush privileges;
```

php的修改,主要是配置的

```php
#主要是要把php-fpm.d/www.conf里面的 下面的注释打开
clear_env = no
env[PATH] = /usr/local/bin:/usr/bin:/bin
#php.ini里面的禁用的exec,system,shell_exec解禁
disable_functions = 
#内存限制扩大到512m
memory_limit = 512M
#最大长传扩大到1G
upload_max_filesize = 1G
```

## centos设置

* 磁盘设置,因为旧笔记本上2块磁盘,一个固态硬盘用来装系统,另外一个机械硬盘用来放数据,机械硬盘格式化,命令参考了[^1]

    ```shell
    sudo su root
    fdisk -l
    fdisk /dev/sdb
    m d a w
    # 更新linux核心系统分区表
    partprobe -s
    mkfs.xfs -f /dev/sdb1
    mkdir /data
    mount /dev/sdb1 /data
    # 新增挂载
    vim /etc/fstab
    /dev/sdb1       /data                           xfs     defaults        0 0
    ```

* 盒盖不休眠不断网

    ``` shell
    sudo vim /etc/systemd/logind.conf
    HandleLidSwitch=lock
    #设置完之后重启
    systemctl restart systemd-logind
    ```

* 设置阿里云镜像

    ``` shell
    sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    sudo wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    sudo mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
    sudo mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
    sudo wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    ```

* 安装ffmpeg

    ``` shell
    sudo yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
    sudo yum install ffmpeg ffmpeg-devel
    ```

* 安装imagick
  * 安装imagick

    ``` shell
    wget http://soft.vpser.net/web/imagemagick/ImageMagick-7.1.0-33.tar.xz
    tar -xvf ImageMagick-7.1.0-33.tar.xz 
    cd ImageMagick-7.1.0-33/
    ./configure --prefix=/usr/local/imagemagick
    make
    sudo make install 
    ```

  * 安装imagick的php扩展

    ``` shell
    wget https://pecl.php.net/get/imagick-3.7.0.tgz
    tar -xvf imagick-3.7.0.tgz 
    cd imagick-3.7.0/
    /usr/local/php/bin/phpize
    ./configure --with-php-config=/usr/local/php/bin/php-config --with-imagick=/usr/local/imagemagick
    make
    sudo make install
    ```

    编辑sudo vim /usr/local/php/etc/php.ini 添加：extension=imagick.so
* 安装redis
  * 安装redis

    ```shell
    wget https://github.com/redis/redis/archive/7.0.2.tar.gz
    tar -xvf 7.0.2.tar.gz 
    cd redis-7.0.2/
    sudo make PREFIX=/usr/local/redis install
    sudo mkdir -p /usr/local/redis/etc/
    sudo cp redis.conf  /usr/local/redis/etc/
    sudo sed -i 's/daemonize no/daemonize yes/g' /usr/local/redis/etc/redis.conf
    sudo sed -i 's#^pidfile /var/run/redis_6379.pid#pidfile /var/run/redis.pid#g' /usr/local/redis/etc/redis.conf
    #拷贝lnmp目录下面的init.d/init.d.redis 到 /etc/init.d/redis
    sudo cp ~/lnmp1.9/init.d/init.d.redis /etc/init.d/redis
    sudo chmod +x /etc/init.d/redis
    sudo chkconfig --add redis
    sudo chkconfig redis on
    ```

  * php安装redis扩展

    ```shell
    wget https://github.com/phpredis/phpredis/archive/refs/tags/5.3.7.tar.gz
    tar -xvf 5.3.7.tar.gz 
    cd phpredis-5.3.7/
    /usr/local/php/bin/phpize
    ./configure --with-php-config=/usr/local/php/bin/php-config
    make
    sudo make install
    sudo vim /usr/local/php/etc/php.ini 
    #添加extension=redis.so
    ```

## nginx配置

```nginx
upstream php-handler {
    #server 127.0.0.1:9000;
    #server unix:/run/php-fpm/www.sock;
    server unix:/tmp/php-cgi.sock;
}


server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name nextcloud.jnff.cc;
    # Path to the root of your installation
    root /home/wwwroot/nextcloud;

    error_page  497 https://$host:$server_port$request_uri;
    # Use Mozilla's guidelines for SSL/TLS settings
    # https://mozilla.github.io/server-side-tls/ssl-config-generator/
    # NOTE: some settings below might be redundant
    ssl_certificate /usr/local/nginx/conf/ssl/cert.pem;
    ssl_certificate_key /usr/local/nginx/conf/ssl/key.pem;

    # Add headers to serve security related headers
    # Before enabling Strict-Transport-Security headers please read into this
    # topic first.
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
    #
    # WARNING: Only add the preload option once you read about
    # the consequences in https://hstspreload.org/. This option
    # will add the domain to a hardcoded list that is shipped
    # in all major browsers and getting removed from this list
    # could take several months.
    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "none" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Remove X-Powered-By, which is an information leak
    fastcgi_hide_header X-Powered-By;


    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # The following 2 rules are only needed for the user_webfinger app.
    # Uncomment it if you're planning to use this app.
    #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
    #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;

    # The following rule is only needed for the Social app.
    # Uncomment it if you're planning to use this app.
    #rewrite ^/.well-known/webfinger /public.php?service=webfinger last;

    location = /.well-known/carddav {
        return 301 $scheme://$host:$server_port/remote.php/dav;
    }
    location = /.well-known/caldav {
        return 301 $scheme://$host:$server_port/remote.php/dav;
    }

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is built with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location / {
        rewrite ^ /index.php;
    }

    location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
        set $path_info $fastcgi_path_info;
        try_files $fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $path_info;
        fastcgi_param HTTPS on;
        # Avoid sending the security headers twice
        fastcgi_param modHeadersAvailable true;
        # Enable pretty urls
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
        try_files $uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js, css and map files
    # Make sure it is BELOW the PHP block
    location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers (It is intended to
        # have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read into
        # this topic first.
        add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Optional: Don't log access to assets
        access_log off;
        }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap)$ {
        try_files $uri /index.php$request_uri;
        # Optional: Don't log access to other assets
        access_log off;
    }
}

```

## nextcloud配置

初始化nextcloud可以使用命令行[^2]

```shell
cd ~/nextcloud/
sudo -u www php occ  maintenance:install --database "mysql" --database-name "nextcloud"  --database-user "user" --database-pass "password" --admin-user "user" --admin-pass "password" --data-dir "/data"
```

修改nextcloud的安装目录conf/config.php添加如下配置  

```php
'memcache.local' => '\OC\Memcache\Redis',
'memcache.distributed' => '\OC\Memcache\Redis',
'redis' => [
        'host' => 'localhost', 
        'port' => 6379,
        'dbindex' => 1,
],
'enabledPreviewProviders' => [
    'OC\Preview\PNG',
    'OC\Preview\JPEG',
    'OC\Preview\GIF',
    'OC\Preview\BMP',
    'OC\Preview\XBitmap',
    'OC\Preview\MP3',
    'OC\Preview\TXT',
    'OC\Preview\MarkDown',
    'OC\Preview\OpenDocument',
    'OC\Preview\Krita',
    'OC\Preview\Illustrator',
    'OC\Preview\HEIC',
    'OC\Preview\Movie',
    'OC\Preview\MSOffice2003',
    'OC\Preview\MSOffice2007',
    'OC\Preview\MSOfficeDoc',
    'OC\Preview\PDF',
    'OC\Preview\Photoshop',
    'OC\Preview\Postscript',
    'OC\Preview\StarOffice',
    'OC\Preview\SVG',
    'OC\Preview\TIFF',
    'OC\Preview\Font',
],
```

以管理员账号登录nextcloud->Settings->Basic settings 里面选择推荐的cron模式
![img](/assets/nextcloud-settings.png){:width="1029px" height="423px"}

以root用户添加定时器任务 crontab -e

```shell
*/5 * * * * sudo -u www /usr/local/php/bin/php /home/wwwroot/nextcloud/cron.php &
```

## 优化

nextcloud安装好之后，打开每个页面都要loading很久，所以需要对参数进行优化

### 解除nextcloud上传文件块大小限制

``` shell
cd /var/www/nextcloud
sudo -u www-data php occ config:app:set files max_chunk_size --value 0
```

### enable php opcache

```shell
vim /usr/local/php/etc/php.ini
# 打开下面注释
opcache.enable = 1
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.memory_consumption = 128
opcache.save_comments = 1
opcache.revalidate_freq = 1
```

## ddns配置

定时检查域名是否改变,如果变了同步修改阿里云的域名解析  
安装python

```shell
sudo su root
yum install python2-pip
yum install python3-pip
pip3 install --upgrade pip -i https://mirrors.aliyun.com/pypi/simple/
pip3 install aliyun-python-sdk-core-v3 -i https://mirrors.aliyun.com/pypi/simple/
pip3 install aliyun-python-sdk-domain -i https://mirrors.aliyun.com/pypi/simple/
pip3 install aliyun-python-sdk-alidns -i https://mirrors.aliyun.com/pypi/simple/
pip3 install requests -i https://mirrors.aliyun.com/pypi/simple/
```

nextcloud安装目录新建ddns.py

```python
#!/usr/bin/env python3
# coding= utf-8

from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkalidns.request.v20150109.DescribeSubDomainRecordsRequest import DescribeSubDomainRecordsRequest
from aliyunsdkalidns.request.v20150109.DescribeDomainRecordsRequest import DescribeDomainRecordsRequest
import requests
from urllib.request import urlopen
import json

ipv4_flag = 1  # 是否开启ipv4 ddns解析,1为开启，0为关闭
ipv6_flag = 0  # 是否开启ipv6 ddns解析,1为开启，0为关闭
accessKeyId = "aaa"  # 将accessKeyId改成自己的accessKeyId
accessSecret = "bbb"  # 将accessSecret改成自己的accessSecret
domain = "test.com"  # 你的主域名
name_ipv4 = "nc"  # 要进行ipv4 ddns解析的子域名
name_ipv6 = "ipv6.test"  # 要进行ipv6 ddns解析的子域名


client = AcsClient(accessKeyId, accessSecret, 'cn-hangzhou')

def update(RecordId, RR, Type, Value):  # 修改域名解析记录
    from aliyunsdkalidns.request.v20150109.UpdateDomainRecordRequest import UpdateDomainRecordRequest
    request = UpdateDomainRecordRequest()
    request.set_accept_format('json')
    request.set_RecordId(RecordId)
    request.set_RR(RR)
    request.set_Type(Type)
    request.set_Value(Value)
    response = client.do_action_with_exception(request)


def add(DomainName, RR, Type, Value):  # 添加新的域名解析记录
    from aliyunsdkalidns.request.v20150109.AddDomainRecordRequest import AddDomainRecordRequest
    request = AddDomainRecordRequest()
    request.set_accept_format('json')
    request.set_DomainName(DomainName)
    request.set_RR(RR)  # https://blog.zeruns.tech
    request.set_Type(Type)
    request.set_Value(Value)    
    response = client.do_action_with_exception(request)


if ipv4_flag == 1:
    request = DescribeSubDomainRecordsRequest()
    request.set_accept_format('json')
    request.set_DomainName(domain)
    request.set_SubDomain(name_ipv4 + '.' + domain)
    request.set_Type("A")
    response = client.do_action_with_exception(request)  # 获取域名解析记录列表
    domain_list = json.loads(response)  # 将返回的JSON数据转化为Python能识别的

    ip = urlopen('https://api-ipv4.ip.sb/ip').read()  # 使用IP.SB的接口获取ipv4地址
    ipv4 = str(ip, encoding='utf-8')
    print("获取到IPv4地址：%s" % ipv4)

    if domain_list['TotalCount'] == 0:
        add(domain, name_ipv4, "A", ipv4)
        print("新建域名解析成功")
    elif domain_list['TotalCount'] == 1:
        if domain_list['DomainRecords']['Record'][0]['Value'].strip() != ipv4.strip():
            update(domain_list['DomainRecords']['Record'][0]['RecordId'], name_ipv4, "A", ipv4)
            print("修改域名解析成功")
        else:  # https://blog.zeruns.tech
            print("IPv4地址没变")
    elif domain_list['TotalCount'] > 1:
        from aliyunsdkalidns.request.v20150109.DeleteSubDomainRecordsRequest import DeleteSubDomainRecordsRequest
        request = DeleteSubDomainRecordsRequest()
        request.set_accept_format('json')
        request.set_DomainName(domain)  # https://blog.zeruns.tech
        request.set_RR(name_ipv4)
        request.set_Type("A") 
        response = client.do_action_with_exception(request)
        add(domain, name_ipv4, "A", ipv4)
        print("修改域名解析成功")


if ipv6_flag == 1:
    request = DescribeSubDomainRecordsRequest()
    request.set_accept_format('json')
    request.set_DomainName(domain)
    request.set_SubDomain(name_ipv6 + '.' + domain)
    request.set_Type("AAAA")
    response = client.do_action_with_exception(request)  # 获取域名解析记录列表
    domain_list = json.loads(response)  # 将返回的JSON数据转化为Python能识别的

    ip = urlopen('https://api-ipv6.ip.sb/ip').read()  # 使用IP.SB的接口获取ipv6地址
    ipv6 = str(ip, encoding='utf-8')
    print("获取到IPv6地址：%s" % ipv6)

    if domain_list['TotalCount'] == 0:
        add(domain, name_ipv6, "AAAA", ipv6)
        print("新建域名解析成功")
    elif domain_list['TotalCount'] == 1:
        if domain_list['DomainRecords']['Record'][0]['Value'].strip() != ipv6.strip():
            update(domain_list['DomainRecords']['Record'][0]['RecordId'], name_ipv6, "AAAA", ipv6)
            print("修改域名解析成功")
        else:  # https://blog.zeruns.tech
            print("IPv6地址没变")
    elif domain_list['TotalCount'] > 1:
        from aliyunsdkalidns.request.v20150109.DeleteSubDomainRecordsRequest import DeleteSubDomainRecordsRequest
        request = DeleteSubDomainRecordsRequest()
        request.set_accept_format('json')
        request.set_DomainName(domain)
        request.set_RR(name_ipv6)  # https://blog.zeruns.tech
        request.set_Type("AAAA") 
        response = client.do_action_with_exception(request)
        add(domain, name_ipv6, "AAAA", ipv6)
        print("修改域名解析成功")
```

以root用户执行

```shell
chmod +x /home/wwwroot/nextcloud/ddns.py
crontab -e
*/1 * * * * /home/wwwroot/nextcloud/ddns.py
```

[^1]: https://zq99299.github.io/linux-tutorial/tutorial-basis/07/03.html#%E7%A3%81%E7%9B%98%E6%A0%BC%E5%BC%8F%E5%8C%96%EF%BC%88%E5%BB%BA%E7%AB%8B%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F%EF%BC%89
[^2]: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#command-line-installation-label