---
layout: post
title: 软件架构
date:   2022-08-17 08:01:36 +0800
categories: 软件架构,中间件
tags:
- 软件架构
---

常见架构，中间件汇总

## 数据库 {#database}

### 数据库架构三种模式

1. shared everything
    完全透明共享cpu/memory/io, 并行能力最差，典型代表是SQLServer
2. shared disk
    共享磁盘系统，处理单元有自己私有的cpu/memory，典型代表是Oracle Rac。数据共享，通过增加节点来提高并行处理能力。但是当磁盘接口达到饱和后，增加节点并不能获得更高的性能。
3. shared nothing
    每个处理单元都有自己私有的cpu/memory/磁盘，不共享任何资源。典型代表DB2。处理单元之间通过协议通信，每个节点相互独立，各自处理自己的数据，处理后的结果向上层汇总。

### 目前商用数据库分类

1. SMP（Symmetric Multi-Processor）（对称多处理器结构）
    对称多处理器结构，服务器的多个cpu对称工作，无主次或从属关系。**SMP的主要特点是共享**,系统中的所有资源（如CPU/memory/io等)都是共享的。所以SMP服务器的扩展能力非常有限。
2. NUMA（Non-Uniform Memory Access）（非一致存储访问结构）
    非一致存储访问结构，
3. MPP（Massive-Parallel Processing）（大规模并行处理结构）
