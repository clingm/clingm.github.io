---
title: Dive Into Coppersmith
date: 2023-12-15T15:18:33+08:00
mathjax: true
tags:
  - Crypto
description:
---


Introduction of Coppersmith’s Method
------------------------------------

1996年 Don Coppersmith 发表了两片论文，“Finding a Small Root of a Univariate Modular Equation”, “Finding a Small Root of a Bivariate Integer Equation; Factoring with High Bits Known”，第一篇讨论如何求单变量模方程的小根，第二篇讨论如何求双变量整数方程的小根，并且把整数方程拓展到了模方程。

Coppersmith’s Method 在公钥密码学中有举足轻重的地位，在大多数RSA的攻击文章中都有涉及到。所以感觉还是不能就停留在平常打CTF比赛中随便调用一下 `small_roots` 就ok的程度，至少要知道其中的原理。

这次的学习主要基于Steven Galbraith教授写的 “Mathematics of Public Key Cryptograph" 这本书中的第19章的内容。

For Modular Univariate Polynomials
----------------------------------

有多项式 $F(x)=s^d + a\_{d-1}x^{d-1} + \\cdots + a\_1x+a\_0$ 是一个首一的整系数的d次多项式。假设我们知道存在$x\_0$使 $F(x\_0)=0\\ (mod\\ M)$ 并且 $|x\_0| < M^{1/d}$。问题就是找到所有这样子的根。

> PS: 之后将使用 $F\_M(x)$ 来表示模M的多项式，$F(x)$来表示整数多项式。

Coppersmith’s Method 的核心思想是创建一个方程$G(x)$，而且 $G(x\_0)=F\_M(x\_0)=0$，即$G(x)$拥有与$F\_M(x)$相同的解，且$G(x)$的系数足够小可以直接算出$x\_0$。

_Example：_

M=17\*19=323，$F(x)=x^2+33x+215x$ 。我们想找到 $F\_M(x)=0$ 的解，当然可以先给出答案$x\_0=3$，但是 $F(3) \\ne 0$ 。根据Coppersmith’s Method 我们需要找到$G(x)$，这里也先给出 $G(x)=9F(x)-M(x+6)=9x^2-26x-3$。把3带进去发现$G(3)=0$。

接下来为后面的一些符号作解释，$M,X \\in \\mathbb{N}$，$F(x)=\\sum\_{i=0}^{d}a\_ix^i$ ，满足 $F\_M(x)=0$ 的解$x\_0$ 都小于 $M$，即M是$x\_0$的上界。$F(X)=\\sum^{d}\_{i=0}a\_ix^i$，再把它写成行向量

$$ b\_F=(a\_0, a\_1X, a\_2X^2, \\cdots, a\_dX^d) $$

_**Howgrave-Graham**_ 定理

如上述所说的$F(x)$,$X$,$M$,$b\_F$ , 如果 $||b\_F|| < M/\\sqrt{d+1}$，那么 $F(x\_0)=0$.

_**证明**_

有柯西不等式 $(\\sum^{n}\_{i=1}x\_iy\_i)^2 \\le (\\sum^{n}\_{i=1}x\_i)^2(\\sum^{n}\_{i=1}y\_i)^2$ ，就是两个向量乘积的模小于向量模的乘积。当$y\_i=1$，有 $$ \\sum^{n}\_{i=1}x\_i \\le \\sqrt{n\\sum\_{i=1}^{n}x\_i^2} $$

现在 $$ \\begin{aligned} |F(x\_0)|&=\\left|\\sum\_{i=0}^da\_ix\_0^i\\right|\\le\\sum\_{i=0}^d|a\_i||x\_0|^i\\le\\sum\_{i=0}^d|a\_i|X^i\\le\\sqrt{d+1}|b\_F|<\\sqrt{d+1}M/\\sqrt{d+1}=M \\end{aligned} $$

在第三个不等式中用到了柯西不等式。所以 $-M<F(x\_0)<M$，而且$F\_M(x\_0)=0$，得出$F(x\_0)=0$。

> 这个定理非常重要，后面找$G(x)$的核心基础就是HG定理(姑且这么叫它)。

### The Simple Coppersmith Method

令 $F(x)=\\sum^{d}\_{i=0}a\_ix^i$是首一的多项式($a\_d=1$)，我们假设至少有一个$x\_0 < X$，使$F\_M(x\_0)=0$，然后我们再建立d个单项方程$G\_{Mi}(x)=Mx\_i$，这样我们就有d+1个方程，这些方程都有一个共同解$x\_0$（$G\_{Mi}(x)$是模M的方程，所以对于任意的x都有$G\_{Mi}(x)=0$）。将这些方程按行向量的形式组成一个格基$B$，$B$所张的格空间记为$L$ $$ \\left.B=\\left(\\begin{array}{ccccc}M&0&\\cdots&0&0\\\\0&MX&\\cdots&0&0\\\\vdots&&&\\vdots&\\vdots\\\\0&0&\\cdots&MX^{d-1}&0\\\\a\_0&a\_1X&\\cdots&a\_{d-1}X^{d-1}&X^d\\end{array}\\right.\\right) $$

由于是下三角矩阵，所以$det(L)=det(B)=M^dX^{d(d+1)/2}$

然后对$B$作LLL规约，将规约后得到的第一行作为$G(x)$的系数。令$c\_1(d)=2^{-1/2}(d+1)^{-1/d}$，如果$X<c\_1(d)M^{2/d(d+1)}$，那么$F\_M(x)$的任意的根$x\_0$都满足$G(x\_0)=0$

_**证明**_

根据LLL,得到的第一行向量满足 $$ \\begin{aligned}|\\underline{b}\_1|&\\le2^{(n-1)/4}\\det(L)^{1/n}=2^{d/4}M^{d/(d+1)}X^{d/2}\\end{aligned} $$

我们还需要让$\\underline{b}\_1$满足HG定理 $$ 2^{d/4}M^{d/(d+1)}X^{d/2} < M/\\sqrt{d+1} $$

把$X$单独写在一边得到 $$ X<2^{-1/2}(d+1)^{-1/d}M^{2/d(d+1)} $$

> 总结一下：通过LLL取第一行向量作为$G(x)$，那么$G\_M(x\_0)=0$，在此之上$X < c\_1(d)M^{2/d(d+1)}$，即满足HG定理，那么$G(x\_0)=0$，于是我们只用在$G(x)$上求解$x\_0$即可。

_**Example**_

M=10001，$F(x)=x^3+10x^2+5000x-222$，$x\_0=4$

### The Full Coppersmith Method

上面讲到的方法可以进行更好的改进，所以我把上面称为Simple Coppersmith Method，观察上面对与可解的$x\_0$的限制，或者说是对$X$的限制

$$ 2^{d/4}M^{d/(d+1)}X^{d/2} < M/\\sqrt{d+1} $$

对其进行简化得到$M^dX^{d(d+1)/2}=det(L)< M^{d+1}$，有两种方法来提升$X$的大小。1.通过添加`x-shift Polynomials` $x^iF(x)$在增大格的基的维数，同时又不增加$M$的幂数。2. 通过$F\_{M^{k}}(x)^{k}=0$增大$M$的幂数。

在上个例子中，把$M=10001,d=3$带入

$$ M^dX^{d(d+1)/2}=det(L)< M^{d+1} $$

得到 $2^{3/4}(M^3X^6)^{1/4} \\le M/\\sqrt{4}$。计算出$X=2.07$。但我们这个计算出来的是在LLL最坏的情况下，一般LLL出来的最短向量会比理论的小，所以实际的$X$会比理论的大一些。

接下来考虑向$B$里添加两个x-shift Polynomials $xF(x),x^2F(x)$，得到新的$B$

$$ \\left.B=\\left(\\begin{array}{cccccc}M&0&0&0&0&0\\\\0&MX&0&0&0&0\\\\0&0&MX^2&0&0&0\\-222&5000X&10X^2&X^3&0&0\\\\0&-222X&5000X^2&10X^3&X^4&0\\\\0&0&-222X^2&5000X^3&10X^4&X^5\\end{array}\\right.\\right) $$

再把带入进之前的不等式计算出$X=3.11$，看到$X$确实变大了。由此可以推出较为一般的情况：如果加入d-1个x-shift Polynomials ($xF(x)-x^{d-1}F(x)$)，然后再用之前的方法可以计算出$X\\approx M^{1/(2d-1)}$

完整的Coppersmith定理结合了x-shift Polynomials 和 powers of $F(x)$。

_**Coppersmith定理**_： 令$0 < \\epsilon < min{0.18, 1/d}$，$F\_M(x)$至少有一个根$x\_0$满足$|x\_0| < \\frac{1}{2}M^{1/d-\\epsilon}$, 那么$x\_0$可以在多项式时间内找到。

_**证明**_ 令$h>1$为一个取决于$d$和$\\epsilon$的整数，并且由下面的等式决定。考虑对应于多项式$G\_{ij}=M^{h-1-j}F(x)^jx^i\\ for\\ 0\\le i < d, 0\\le j<h$构造的格$L$，$G\_{ij}\\equiv 0\\mod{M^{h-1}}$。$L$的维度等于$dh$。由于$L$还是一个下三角矩阵，所以可以计算行列式 $$ \\det(L)=M^{(h-1)hd/2}X^{(dh-1)dh/2} $$

对$L$进行LLL规约得到的第一行向量$\\underline{b}\_1$满足 $$ |\\underline{b}\_1|<2^{(dh-1)/4}\\det(L)^{1/dh}=2^{(dh-1)/4}M^{(h-1)/2}X^{(dh-1)/2} $$

该向量对应于$dh-1$次多项式$G(x)$，而且$G\_{M^{h-1}}(x\_0)=0$。如果$||\\underline{b}\_1||<M^{h-1}/\\sqrt{dh}$，即满足HG定理那么$G(x\_0)=0$，就可以求解$x\_0$了。

接下来证明为何$|x\_0|<\\frac{1}{2}M^{1/d-\\epsilon}$。

> 其实这里俺也没看懂（🐶

$$ \\sqrt{dh}2^{(dh-1)/4}M^{(h-1)/2}X^{(dh-1)/2}<M^{h-1} $$

把M除过去得 $$ \\sqrt{dh}2^{(dh-1)/4}X^{(dh-1)/2}<M^{(h-1)/2} $$

$$ c(d,h)X<M^{(h-1)/(dh-1)} $$

$$ c(d,h)=(\\sqrt{dh}2^{(dh-1)/4})^{2/(dh-1)}=\\sqrt{2}(dh)^{1/(dh-1)} $$

然后先看 $$ \\begin{aligned}\\frac{h-1}{dh-1}=\\frac{1}{d}-\\frac{d-1}{d(dh-1)}\\end{aligned} $$

令$(d-1)/(d(dh-1))=\\epsilon$得 $$ h=((d-1)/(d\\epsilon)+1)/d\\approx1/(d\\epsilon) $$

注意$dh=1+(d-1)/(d\\epsilon)$所以$c(d,h)=\\sqrt{2}(1+(d-1)/(d\\epsilon))^{d\\epsilon/(d-1)}$，当$\\epsilon$趋近0时收敛于$\\sqrt{2}$。应为要求$X<\\frac{1}{2}M^{1/d-\\epsilon}$要求$\\frac{1}{2}\\le\\frac{1}{c(d,h)}$。$x=d\\epsilon/(d-1)$相当于$(1+1/x)^x<\\sqrt{2}$，对于$0\\le x<0.18$成立。因此假设$\\epsilon\\le(d-1)/d$。

把h向上取证，如果使得 $$ |x\_0| < \\frac{1}{2}M^{1/d-\\epsilon} $$

就可以使用LLL和多项式求根解出$x\_0$。
