---
layout: post
title: electron与pro.antd整合支持typescript
date:   2022-06-17 9:58:36 +0800
categories: electron pro.antd typescript
tags:
- electron pro.antd typescript
---

electron与pro.antd的整合,支持typescript, 总的思路是先创建typescript版本的pro.antd,然后逐步添加electron.

## 添加electron

先创建typescript版本的pro.antd的项目,然后再往项目上添加electron.

```shell
yarn add electron -D
```

## 整合electron与typescript

因为antd安装的时候选择了typescript版本,所以不需要安装typescript,只需要配置electron对typescript的支持即可, 原理是先把typescript编译成js,然后引用编译后的js,typescript支持一个项目下有多个typescript的项目配置,
`tsc -p`可以指定使用哪个目录下的tsconfig.json, 我是把electron的所有文件放在了src/electron目录下面,所以新建src/electron/tsconfig.json添加如下配置

```json
{
    "compilerOptions": {
        "target": "es5",
        "module": "commonjs",
        "sourceMap": false,
        "strict": true,
        #这里要注意目录层级,我的源文件是放在了src/electron/下面,
        #而编译好的文件和antd编译的文件放在一起,都放在了项目根目录的dist下面
        "outDir": "../../dist",
        "rootDir": "../../",
        "noEmitOnError": true,
        "typeRoots": [
            "node_modules/@types"
        ]
    }
}
```

经过上面的配置,通过`tsc -p src/electron -w`命令就会把ts文件编译成js,然后放在了项目根目录的dist目录下(与antd保持一致),目录层级保持不变,比如src/electron/main.ts编译后存在了dist/src/electron/main.js  

修改项目根目录的`package.json`添加electron的入口, 只显示了增加部分,原来的保持不变

```json
{
  # 添加这一行,要与上一步配置的typescript编译后输出保持一致
  "main": "dist/src/electron/main.js",
  "scripts": {
    # 编译electron的ts文件
    "build:electron":"tsc -p src/electron -w",
    # 运行electron
    "dev:electron":"electron ."
  }
}
```

## 便捷配置

为了让项目运行起来,我创建了scr/electron/main.ts文件,并输入一下内容

```typescript
import { app, BrowserWindow } from 'electron';
import * as path from 'path';
import installExtension, { REACT_DEVELOPER_TOOLS } from "electron-devtools-installer";

function createWindow() {
    const win = new BrowserWindow({
        width: 800,
        height: 600,
    });
    win.loadURL('http://localhost:3000');

    win.webContents.openDevTools();
}

app.whenReady().then(() => {
  // DevTools
  installExtension(REACT_DEVELOPER_TOOLS)
    .then((name) => console.log(`Added Extension:  ${name}`))
    .catch((err) => console.log('An error occurred: ', err));

  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });

  app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
      app.quit();
    }
  });
});
```

经过上诉的操作,通过`npm run dev`启动antd, `npm run build:electron` 编译electron的ts文件,然后`npm run dev:electron` 就可以启动electron了,每次都敲入这么多命令很麻烦, 可以通过`concurrently` 把多条命令结合到一起, 在把多条命令结合到一起的时候,需要等待上一条命令运行完再运行下一条,这个就需要用 `wait-on`来实现.

```shell
# 方便开发调试打包，本来要执行多次npm run xxx 通过concurrentlly可以合并成一条命令
yarn add concurrently -D 
# 配合concurrently使用
yarn add wait-on -D 
```

修改项目的package.json文件

```json
{
  # 添加这一行,要与上一步配置的typescript编译后输出保持一致
  "main": "dist/src/electron/main.js",
  "scripts": {
    # 运行electron
    "dev:electron":"concurrently \"npm run start:dev\" \"wait-on http://localhost:8000 && tsc -p src/electron -w\" \"wait-on http://localhost:8000 && tsc -p src/electron && electron .\""
  }
}
```

这样只需要执行`npm run dev:electron` 一条命令就可以启动electron了,

## antd的配置修改

如果你执行了`npm run dev:electron`,会发现项目有问题,因为还需要对antd做一点点的修改,主要是修改 config/config.ts文件.

```typescript
export default defineConfig({
    hash: true,
    // 默认是browser,打包后会出现页面找不到加载不出来的情况,所以修改为hash
    history: { type: 'hash' },
    // 默认值是'/'，需要改成"./" 
    publicPath: './',
    // 主要是为了把scr/electron下面编写的html文件也拷贝到dist目录下面
    copy:[
        'src/electron/**/*.html'
    ]
});
```
