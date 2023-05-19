---
layout: post
title: mail mime
date:   2023-05-18 13:58:36 +0800
categories: mail mime
tags:
- mail mime
---

开发时间久了难免遇到自动发邮件，收邮件的需求，记录一下与邮件相关的内容

## MIME

Multipurpose Internet Mail Extensions（多用于互联网邮件扩展），扩展了电子邮件标准，用来支持
* 非ASCII文字，
* 非文本文字（例如声音图片等）

[rfc地址](https://datatracker.ietf.org/doc/html/rfc2046)

### MIME-version

用来标识MIMIE版本
```shell
MIME-Version: 1.0
```

### Content-Type

用来表示内容类型

```shell
Content-Type: [type]/[subtype]: parameter
```

type和subtype的形式：

* Text: 文本
  * plain: 纯文本的内容
  * html: html格式的
* Multipart: 消息体有多个部分
  * mixed
    用来表示所包含的多个部分包含了不同的Content-Type或者附件，默认的每个子部分的Content-Type都是'text/plain'类型
  * digest
    用来表示包含多个文本消息，每个子部分默认的Content-Type都是'message/rfc822'
  * alternative
    用来表示所包含的多个子部分表达的内容是相同的，只是每个子部分的Content-Type不同，每个子部分的顺序很重要，客户端按照可以处理的子部分的顺序来显示
    一般multipart/alternative类型的消息包含两部分html格式和text/plain格式的，当客户端无法显示html的时候，使用text/plain内容来兜底
  * related
  * report
  * signed
  * encrypted
  * form-data
  * x-mixed-replace
  * byterange
* Application: 
* Message: 包装的email消息
* Image: 静态图片资料
* Aduio: 音频或者声音
* Video: 视频
* Font: 字体文件
* Model: 3D模型文件

### Content-Disposition

用来标识内容的表现形式

* inline
  表示消息要自动显示出来
* attachment
  表示消息不自动显示，需要用户自己来处理

```shell
Content-Disposition: attachment; filename=test.png;
  modification-date="Wed, 12 Feb 1997 16:29:51 -0500";
```
