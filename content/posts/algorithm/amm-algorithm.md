---
title: AMM Algorithm
date: 2022-10-03T00:51:50+08:00
mathjax: true
tags:
  - Algorithm
description:
---


### refere：[1111.4877.pdf (arxiv.org)](https://arxiv.org/pdf/1111.4877.pdf)

AMM平方根提取算法可以被拓展到一般的$r^{th}$根提取问题上，并且要求


$r\\mid p -1，(m, r)=1$

AMM算法的核心观点暨在有限域$F\_p$上开2次方的方法
-----------------------------

AMM在有限域$F\_p$中开平方根，这要求$p$是一个素数，那么$p$就可以写成$2^t\\cdot s$的形式，其中$s$是奇数。对于一个二次剩余$\\delta$和二次非剩余$\\rho$，我们有

$$ (\\delta^{s})^{2^{t - 1}}\\equiv1\\pmod{p}，(\\rho^{s})^{2^{t - 1}}\\equiv-1\\pmod{p} $$

如果$t=1$，$\\delta^{s}\\equiv1\\pmod{p}$，两边乘$\\delta$得到

$$ (\\delta^{\\frac{s+1}{2}})^{2} \\equiv \\delta \\pmod{p} $$

所以$\\delta^{\\frac{s+1}{2}}$就是一个根。

当$t\\geq 2$，那么 $(δ^s)^{2^{t−2}} (mod p)\\in { 1, −1}$（虽然在是不知道这是为什么，可能是将他当成一个新的二次（非）剩余），引入$k\_1={0, 1}$，表示成

$$ (\\delta^s)^{2^{t-2}}(\\rho^s)^{2^{t-1}\\cdot k\_1}\\equiv1\\pmod{p} $$

当 $(δ^s)^{2^{t−2}} \\equiv1(mod p)$，$k\_1=0$，$k\_1=1$

然后我们继续对上面的式子开方， $(δ^s)^{2^{t−3}}(\\rho^s)^{2^{t-2}\\cdot k\_1} \\pmod{p}\\in { 1, −1}$，并引入$k\_2$

$$ (\\delta^s)^{2^{t-3}}(\\rho^s)^{2^{t-2}\\cdot k\_1}(\\rho^s)^{2^{t-1}\\cdot k\_2}\\equiv1\\pmod{p} $$

一直这样下去得到

$$ (\\delta^s)(\\rho^s)^{2k\_1+2^2k\_2+\\cdots+2^{t-1}k\_{t-1}}\\equiv1\\pmod{p} $$

因此我们有

$$ (\\delta^{\\frac{s+1}{2}})^2\[(\\rho^s)^{k\_1+2k\_2+\\cdots+2^{t-2}k\_{t-1}}\]^2\\equiv \\delta \\pmod{p} $$

算法的过程

![Untitled.png](https://s2.loli.net/2022/10/02/RWchA1vrIe6wjMH.png)

### Example:

[AMM算法开二次方根](https://www.notion.so/AMM-e0e456024cf54c28a1663c6ea231eee3)

AMM算法在$F\_{p^m}$上开2次方
---------------------

AMM方法在$F\_p$和$F\_{p^m}$上的不同在于，不能通过勒让德符号来判断一个二次非剩余

令$q=p^m$，需要找到一个二次非剩余$\\rho$，就要求$\\rho^{\\frac{q-1}{2}}\\neq1$，如何去找呢，只要在$F^\*\_{p^m}$中随机取值验证就行了。

算法过程和上面的差不多

![Untitled 1.png](https://s2.loli.net/2022/10/02/M6DZfHyQeUuqrYv.png)

AMM开3次方
-------

差不多就是把2变成3

直接贴算法过程吧

![Untitled 2.png](https://s2.loli.net/2022/10/02/eOEAFzrusJ4gkbB.png)

AMM开$r^{th}$方法
--------------

对于一般情况的等式$X^r=\\delta$在有限域$F\_q$中，分为两种情况

$$ (1)(r, q - 1) = 1;\\quad (2)r\\mid {q-1} $$

对第一种情况，就是RSA了，求出$rd\\equiv1\\pmod{q}$，$\\delta^d\\equiv X\\pmod{q}$

所以只要充分考虑第二种情况即可。

### Example

[AMM算法代码实现](https://www.notion.so/AMM-acbf1df77dc54e2ea422cbb38d93a638)
