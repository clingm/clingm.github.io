---
title: Hitcon Ctf 2022 Superprime
date: 2022-11-30T15:42:47+08:00
mathjax: true
tags:
  - Crypto
description:
---



> 继续复现HITCON CTF 的赛题。争取近期全部复现完。

源码
--

chall.py

    from Crypto.Util.number import getPrime, isPrime, bytes_to_long
    
    def getSuperPrime(nbits):
        while True:
            p = getPrime(nbits)
            pp = bytes_to_long(str(p).encode())
            if isPrime(pp):
                return p, pp
    
    
    p1, q1 = getSuperPrime(512)
    p2, q2 = getSuperPrime(512)
    p3, q3 = getSuperPrime(512)
    p4, q4 = getSuperPrime(512)
    p5, q5 = getSuperPrime(512)
    
    n1 = p1 * q1
    n2 = p2 * p3
    n3 = q2 * q3
    n4 = p4 * q5
    n5 = p5 * q4
    
    e = 65537
    c = bytes_to_long(open("flag.txt", "rb").read().strip())
    for n in sorted([n1, n2, n3, n4, n5]):
        c = pow(c, e, n)
    
    print(f"{n1 = }")
    print(f"{n2 = }")
    print(f"{n3 = }")
    print(f"{n4 = }")
    print(f"{n5 = }")
    print(f"{e = }")
    print(f"{c = }")
    

思路
--

首先可以令

$$ f(x)=bytes\\\_to\\\_long(str(x).encode()) $$ 通过long\_to\_bytes源码，知道这这个函数就是把参数的每一个字节转成16进制然后拼起来。假设

$$ \begin{aligned} x &= a\_0 + a\_1_10 + a\_2_10^2 + \\cdots \\\ &= \\sum\_{i=0}^na\_i\*10^i \end{aligned} $$ 那么

$$ \begin{aligned} f(x) &= (a\_0 + 48) + (a\_1 + 48)«8 + (a\_2 + 48)«16 + \cdots\\\ &=(a\_0 + 48) + (a\_1 + 48)\*2^{8} + (a\_2+48)\*2^{16}+\cdots\\\ &=\sum\_{i=0}^{n}(a\_i+48)\*256^{i} \end{aligned} $$ 根据题目我们可以把题目分解成三个部分

    # part 1
    n1 = p1 * q1
    # part 2
    n2 = p2 * p3
    n3 = q2 * q3
    # part 3
    n4 = p4 * q5
    n5 = p5 * q4
    

### Part 1

很容易知道$f(x)$是单调递增的，就可以用二分法搜索，时间复杂度为$O(logN)$，最多查找512次，这个时间复杂度是非常低的。

    def binary_search(n):
        L, R = 0, 2**512
        while L <= R:
            middle = (L+R) // 2
            v = middle*f(middle)
            if v > n:
                R = middle
            elif v < n:
                L = middle
            else:
                return middle
    

最后确实找了512次，只用了一秒不到。

### Part 2

从`n2`, `n3`的表达式得到

$$ \\begin{aligned} n\_2 &= p\_2\*p\_3 \\\\ &=(a\_{01}+a\_{11}\*10+a\_{21}_10^2+\\cdots+)_(a\_{02}+a\_{12}\*10+a\_{22}_10^2+\\cdots+) \\end{aligned} $$ $$ \\begin{aligned} n\_3&=q\_2_q\_3 \\\\ &= \[(a\_{01}+48) + (a\_{11}+48)\*256 + (a\_{21}+48)_256^2+\\cdots+\]_\[(a\_{02}+48)+(a\_{12}+48)\*256+(a\_{22}+48)\*256^2+\\cdots+\] \\end{aligned} $$

可以推出

$$ \\begin{aligned} n\_2 &\\equiv a\_{01}\*a\_{02} \\pmod{10} \\\\ n\_2 &\\equiv (a\_{01} + a\_{11}_10)_(a\_{02}+a\_{12}\*10) \\pmod{10^2} \\\\ &\\vdots \\\\ n\_2 &\\equiv (a\_{01} + \\cdots+a\_{n1}_10^n)_(a\_{02} + \\cdots+a\_{n2}\*10^n) \\pmod{10^{n+1}} \\end{aligned} $$

$$ \\begin{aligned} n\_3 &\\equiv (a\_{01}+48)\*(a\_{02}+48) \\pmod{256}\\\\ &\\vdots\\\\ n\_3&\\equiv\[(a\_{01}+48)+\\cdots+(a\_{n1}+48)_256^n\]_\[(a\_{02}+48)+\\cdots+(a\_{n2}+48)\*256^n\] \\pmod{256^{n+1}} \\end{aligned} $$

欸？是不是感觉似曾相识。很像BabySSS这道题的处理，不过这里有两个未知变量，但是对于每一个模10和256的幂，有两个方程，而且$a\_{i1}$和$a\_{i2}$的取值都在$\[0, 9\]$ 这个区间内，可以爆破。具体的方法使用到了Prune and Search搜索算法。

    #Prune and Search
    #official writeup from maple3142
    
    def factor2(n1, n2):
        n1p = None
    
        def test_digits(ps, qs):
            nonlocal n1p
            if n1p is not None:
                return False
            p = sum([pi * 10**i for i, pi in enumerate(ps)])
            pp = sum([(48 + pi) * 256**i for i, pi in enumerate(ps)])
            q = sum([pi * 10**i for i, pi in enumerate(qs)])
            qq = sum([(48 + pi) * 256**i for i, pi in enumerate(qs)])
            if p != 0 and p != 1 and n1 % p == 0:
                n1p = p
                return False
            m1 = 10 ** len(ps)
            m2 = 256 ** len(qs)
            return (p * q) % m1 == n1 % m1 and (pp * qq) % m2 == n2 % m2
    
        def find_ij(ps, qs):
            for i in range(10):
                for j in range(10):
                    if test_digits(ps + [i], qs + [j]):
                        yield i, j
    
        def search(ps, qs):
            for i, j in find_ij(ps, qs):
                search(ps + [i], qs + [j])
    
        search([], [])
        n2p = bytes_to_long(str(n1p).encode())
        assert n2 % n2p == 0
        return (n1p, n1 // n1p), (n2p, n2 // n2p)
    

### Part 3

官方wp的解决方法是把$n\_4$看成

$$ \\begin{aligned} n4&=p\_4_f(p\_5) \\\\ &=p\_4_f(\\frac{n\_5}{f(p4)}) \\end{aligned} $$

然后在$p\_4$的长度不变的时候，$n\_4$也是一个单调递增的，就可以用二分搜索分解。 [offical writeup](https://github.com/maple3142/My-CTF-Challenges/tree/master/HITCON%20CTF%202022/Superprime)

    def factor3(n1, n2):
        def try_factor(l, r): #二分搜索
            while l < r:
                m = (l + r) // 2
                if m > 1 and n1 % m == 0:
                    return m
                if m * f(n2 // f(m)) < n1:
                    l = m + 1
                else:
                    r = m - 1
    
        for i in range(16):
            # brute force top 4 bits of p1
            # because len(str(p1)) must be constant to have monotonic property
            l = i << 508
            r = l + (1 << 508)
            if p1 := try_factor(l, r):
                return (p1, n1 // p1), (f(p1), n2 // f(p1))
    

最后所有的n都分解了，解5次rsa就可以了。

总结
--

这道题并没有考到很多密码学上的知识，而是一些非常有用的搜索算法，以及数学上的变换。通过这道题，学习了很多，包括Prune and Search还有对于时间复杂度的估算的应用。
