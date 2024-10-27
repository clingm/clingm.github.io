---
title: Hidden Number Problem
date: 2022-11-18T15:49:12+08:00
mathjax: true
tags:
  - Crypto
description:
---


> 在最近的很多比赛都遇到了这个Hidden Number Problem(HNP)，所以抽个时间来仔细学习一下，然后马上要HGAME2023了，正好准备一下题目给新生写。

Introduce
---------

HNP问题第一次被提出是在这篇论文中 [“Hardness of computing the most significant bits of secret keys in Diffie-Hellman and related schemes” by Dan Boneh and Ramarathnam Venkatesan](https://crypto.stanford.edu/~dabo/pubs/abstracts/dhmsb.html)。HNP问题本来是用来研究Diffie-Hellman共享密钥中的最高有效位是否与整个秘密一样难以计算？并且D. Boneh和R. Venkatesan还展示了一种有效的算法，用于在有足够大的位泄漏的情况下恢复密钥。

> 这个方法用到了格和格基规约的算法，一开始学习格密码时把重点放在了基于格的密钥系统的学习上，但格终究是数学上的东西，数学说白了就是一个工具，那么格自然也是一个工具，只不过我们把格这个有力的工具用在了密码分析上而已。

How is the HNP defined
----------------------

论文中首先提出了most significant bits（MSB）的定义。首先令$p$是一个素数，$n$是$p$的二进制位数，即$n=log\_2(p)$，用$x\\ mod\\ p$来表示一个定义在有限域的数$a \\in GF(p)$，即$x \\equiv a \\pmod{p}$。定义$MSB\_k(x)$的值为$t$并且 $(t-1)\\cdot p/2^k\\leq x <t \\cdot p/2^k$，或者更简单的定义 $$ MSB\_k(x)=z,\\quad |x-z|< p/2^k $$

**About the $MSB\_k(x)$**

一看到most signficant bits可能很多人都会想当然的认为是$x$的最高$k$位。其实不然，根据定义，可以写一个小demo

    from random import randint
    from sage.all import *
    from Crypto.Util.number import getPrime
    # Some parameters of the game, chosen for simplicity.
    
    # p - A prime number for our field.
    p = getPrime(128)
    
    # n - The number of bits in `p`.
    n = ceil(log(p, 2))
    
    # k - The number of significant bits revealed by the oracle.
    # Using parameters from Thereom 1.
    k = ceil(sqrt(n)) + ceil(log(n, 2))
    print(f"The number of significant bits = {k}")
    
    def msb(query):
        """Returns the MSB of query based on the global paramters p, k.
        """
        while True:
            z = randint(1, p-1)
            answer = abs(query - z)
            if answer < p / 2**(k+1):
                break
        return z
    
    x = randint(1, p-1)
    print(f"x = {x}")
    print(f"MSB's output = {msb(x)}")
    print(f"most k bit of x = {x >> (n - k)}")
    
    '''
    The number of significant bits = 19
    x = 54914319491231438995398843041850226262
    MSB's output = 54914493779494223381640832877194242316
    |MSB(x) - x| = 124182961411716441204715130169529
    most k bit of x = 84608
    '''
    

如何去理解这个$MSB\_k(x)$呢，不难得出以下几点：

*   根据$MSB\_k(x)$的定义，有$u=x$是一定满足$|x-u|\\leq\\frac{p}{2^{k+1}}$的，那么$u=x$一定是$MSB$的一个输出，为什么是一个呢，因为这个不等式肯定是多解的。
    
*   当$k$增大时，不等式的右边$\\frac{p}{2^{k+1}}$和会快速的缩减，意味着不等式左边的$z$也就是$MSB$的输出要接近$x$。$k$越大，$MSB\_k(x)$越接近$x$。
    

> 由于$k$越大，$MSB\_k(x)$越接近$x$，也就是说，对于越大的$k$，我们得到的数就泄漏了越多的$x$的有效位。

然后定义Hidden Number Problem（HNP）：确定$p$和$k$，已知$MSB\_k(\\alpha g^x\\ mod \\ p)$求$\\alpha$。

> 论文中提到如果可以请求到正确的$MSB\_k(\\alpha\\cdot t\\ mod\\ p)$，这里$t=g^x$，那么恢复$\\alpha$是一件简单的事情。

Main Results
------------

这一节主要讲的是多大的k可以来解决HNP问题。直接上定理。

### Theorem 1

令$\\alpha$是定义在有限域$GF(p)$的一个数， $k=\\lceil\\sqrt{n}\\rceil+\\lceil\\log n\\rceil$，$\\mathcal{O}(t)=\\operatorname{MSB}\_{k}(\\alpha t \\bmod p)$。存在一种算法A可以在多项式时间内解决HNP。

$$ \\underset{t\_{1}, \\ldots, t\_{d}}{\\operatorname{Pr}}\\left\[A\\left(t\_{1}, \\ldots, t\_{d}, \\mathcal{O}\\left(t\_{1}\\right), \\ldots, \\mathcal{O}\\left(t\_{d}\\right)\\right)=\\alpha\\right\] \\geq \\frac{1}{2} $$

其中$d=2\\sqrt{n}$，$t\_1,\\cdots,t\_d$是均匀的，独立的随机从$\\mathbb{Z}\_{p}^{\*}$中选择。

    这里均匀的，独立的随机选择应该是为了保证数据的不相关性。
    

### Theorem 2

设$k=\\lceil\\sqrt{n}\\rceil+\\lceil\\log{n}\\rceil$ ，给出一个有效的算法从$g^a, g^b$计算$MSB\_k(g^{ab})$，存在一个算法可以在多项式时间内计算$g^{ab}$。也就是已知$MSB\_k(g^{ab})$求$g^{ab}$。

Proof
-----

首先回顾一下格这个东西。格可以这个样子定义

$$ L=\\left{y: y=\\sum\_{i=1}^{d} t\_{i} b\_{i}, t\_{i} \\in \\mathbb{Z}\\right} $$

$d$是格$L$的阶，${b\_i}={b\_1,\\cdots,c\_d}$是$L$的一组线性无关向量，被称为$L$的基，$\\sum^{d}\_{i=1}t\_ib\_i$是这个基的一个线性组合。利用LLL格基规约算法可以从一个给定的格$L$和一个点$v$（不必要是格上的点），找到一个最靠近$v$的格点。

接下来证明Theorem 1。

$d=2\\lceil\\sqrt{n}\\rceil$，$k=k=\\lceil\\sqrt{n}\\rceil+\\lceil\\log n\\rceil$，然后假设我们已经获得了$d$个正确的MSB oracle $a\_1, \\cdots, a\_d$，对应的输入为$t\_1,\\cdots,t\_d$。根据MSB的定义，我们有对于所有的a和t

$$ |\\alpha t\_i\\ mod\\ p-a\_i|\\leq p/2^k $$

构造格$L$

$$ \\left(\\begin{array}{cccccc} p & 0 & 0 & \\ldots & 0 & 0 \\\\ 0 & p & 0 & \\ldots & 0 & 0 \\\\ & \\vdots & & & & \\vdots \\\\ 0 & 0 & 0 & \\ldots & p & 0 \\\\ t\_{1} & t\_{2} & t\_{3} & \\ldots & t\_{d} & 1 / p \\end{array}\\right) $$

注意对于最后一行乘$\\alpha$后模$p$可以得到这样一个向量

$$ v\_{\\alpha}=(r\_1,\\cdots,r\_d,\\alpha/p) $$

说明$v\_{\\alpha}$确实存在与格$L$中，其中 $r\_i=\\alpha t\_i\\ mod\\ p$，于是

$$ |r\_i - a\_i|<p/2^k\\quad i\\in\[1,d\] $$

定义向量$u=(a\_1,\\cdots,a\_d,0)$，那么向量$u$和$v\_{\\alpha}$的距离，即$||u-v\_{\\alpha}||$

$$ ||u-v\_{\\alpha}||<\\sqrt{\\sum^{d-1}\_{i=1}(a\_i-r\_i)^2+(\\frac{\\alpha}{p})^2} \\le \\sqrt{d+1}p/2^k $$

那么我们就可以用LLL和Babai算法来寻找到$v\_{\\alpha}$，对$v\_{\\alpha}$的最后一个元素乘$p$就求出了$\\alpha$。

Example & Demo
--------------

demo from [kel](https://kel.bz/post/hnp/).

    from random import randint
    from sage.all import *
    from Crypto.Util.number import getPrime
    # Some parameters of the game, chosen for simplicity.
    
    # p - A prime number for our field.
    p = getPrime(128)
    
    # n - The number of bits in `p`.
    n = ceil(log(p, 2))
    
    # k - The number of significant bits revealed by the oracle.
    # Using parameters from Thereom 1.
    k = ceil(sqrt(n)) + ceil(log(n, 2))
    print(f"The number of significant bits = {k}")
    d = 2*ceil(sqrt(n))
    
    def msb(query):
        """Returns the MSB of query based on the global paramters p, k.
        """
        while True:
            z = randint(1, p-1)
            answer = abs(query - z)
            if answer < p / 2**(k+1):
                break
        return z
    
    def create_oracle(alpha):
        """Returns a randomized MSB oracle using the specified alpha value.
        """
        alpha = alpha
        def oracle():
            random_t = randint(1, p-1)
            return random_t, msb((alpha * random_t) % p)
        return oracle
    
    def build_basis(oracle_inputs):
        """Returns a basis using the HNP game parameters and inputs to our oracle
        """
        basis_vectors = []
        for i in range(d):
            p_vector = [0] * (d+1)
            p_vector[i] = p
            basis_vectors.append(p_vector)
        basis_vectors.append(list(oracle_inputs) + [QQ(1)/QQ(p)])
        return Matrix(QQ, basis_vectors)
    
    def approximate_closest_vector(basis, v):
        """Returns an approximate CVP solution using Babai's nearest plane algorithm.
        """
        BL = basis.LLL()
        G, _ = BL.gram_schmidt()
        _, n = BL.dimensions()
        small = vector(ZZ, v)
        for i in reversed(range(n)):
            c = QQ(small * G[i]) / QQ(G[i] * G[i])
            c = c.round()
            small -= BL[i] * c
        return (v - small).coefficients()
    
    # Hidden alpha scalar
    alpha = randint(1, p-1)
    
    # Create a MSB oracle using the secret alpha scalar
    oracle = create_oracle(alpha)
    
    # Using terminology from the paper: inputs = `t` values, answers = `a` values
    inputs, answers = zip(*[ oracle() for _ in range(d) ])
    
    # Build a basis using our oracle inputs
    lattice = build_basis(inputs)
    print("Solving CVP using lattice with basis:\n%s\n" % str(lattice))
    
    # The non-lattice vector based on the oracle's answers
    u = vector(ZZ, list(answers) + [0])
    print("Vector of MSB oracle answers:\n%s\n" % str(u))
    
    # Solve an approximate CVP to find a vector v which is likely to reveal alpha.
    v = approximate_closest_vector(lattice, u)
    print("Closest lattice vector:\n%s\n" % str(v))
    
    # Confirm the recovered value of alpha matches the expected value of alpha.
    recovered_alpha = (v[-1] * p) % p
    assert recovered_alpha == alpha
    print("Recovered alpha! Alpha is %d" % recovered_alpha)
    

Refer to
--------

*   [The Hidden Number Problem](https://kel.bz/post/hnp/)
*   Hardness of computing the most significant bits of secret keys in Diffie-Hellman and related schemes” by Dan Boneh and Ramarathnam Venkatesan
