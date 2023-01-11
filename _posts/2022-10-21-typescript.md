---
layout: post
title: typescript
date:   2022-10-21 08:01:36 +0800
categories: typescript
tags:
- typescript
---

## typescript

### `keyof` 和查找类型
`keyof`接收对象类型，生成对象类型属性的联合(string or numeric)

```typescript
type Point = {x: number, y: number}
type P = keyof Point;// P = keyof Point 等价于 "x" | "y" 
```

如果类型有 string or numeric index signature， `keyof`返回 string or numeric

``` typescript
type Arrayish = {[n number]: unknown}
type A = keyof Arrayish// A = number

type Mapish = {[k: string]: boolean}
type M = keyof Mapish;// M = string | number
```

注意M是 string \| number，这是因为javascript总是自动转化为string，所以`obj[0]`总是和`obj["0"]`相同

### Partial\<T>

T的所有属性变为`可`选

```tyepscript
type Partial<T> = {
    [P in keyof T]?: T[P];
}
```

### Requried\<T>

T的所有属性变为`必`选

```typescript
type Required<T> = {
    [P in keyof T]-?:T[P];
}
```

### ReadOnly\<T>

T的所有属性变为只读

```typescript
type ReadOnly<T> = {
    readonly [P in keyof T]: T[P];
}
```

### Record\<K extends keyof any, V>

构造一个类型，键类型是K, 值类型是V
```typescript
// K extends keyof T 表示K是 keyof T的子集
type A = keyof any;// 等价于 type A = string | number | symbol

type Record<K extends keyof any, T> = {
    [P in K]: T;
}
```