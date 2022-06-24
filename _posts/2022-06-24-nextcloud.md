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

## centos设置

* 盒盖不休眠不断网

``` shell
sudo vim /etc/systemd/logind.conf
HandleLidSwitch=lock
```

设置完之后重启

``` shell
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

## nextcloud配置

config.php添加如下配置

``` php
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
