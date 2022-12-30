---
title: HITCON CTF 2022 Secret
date: 2022-12-02 17:16:38
tags: [WriteUp, Lattice]
categories: Crypto
katex: true
cover: http://ctf.hitcon.org/img/og_img.png
---

## 源码

prob.py

```python
import random, os
from Crypto.Util.number import getPrime, bytes_to_long

p = getPrime(1024)
q = getPrime(1024)
n = p * q

flag = open('flag','rb').read()
pad_length = 256 - len(flag)
m = bytes_to_long(os.urandom(pad_length) + flag)
assert(m < n)
es = [random.randint(1, 2**512) for _ in range(64)]
cs = [pow(m, p + e, n) for e in es]
print(es)
print(cs)
```

## 思路

### Recover N

题目给出了64组

$$
c_i\equiv m^{p+e_i} \pmod{n}
$$
但是并没有给模数$n$。其实这类题目在N1CTF（EzDLP）以及maple师傅的另一道[题目](https://github.com/maple3142/My-CTF-Challenges/tree/master/ImaginaryCTF/Round%2026/no_modulus)中出现过。

需要恢复模数，就需要构造出像这样的式子

$$
\begin{aligned}
C &\equiv 0 \pmod{n} \\
C &=Kn
\end{aligned}
$$
如果有两个或多个像这样子的同余式，就可以用$\gcd(C_1, C_2)$来恢复$n$。如果我们能找到多组$a_i$，并且$a_i$中有正数也存在负数。使得

$$
\begin{aligned}
\prod c_i^a \equiv m^{p\sum{a_i}}\cdot m^{\sum{e_i\cdot a_i}}\equiv 1 \pmod{n}
\end{aligned}
$$
由于我们不知道$n$，所以不能直接计算模逆，但是可以写成

$$
\prod{c_{i}^{a_i}}\equiv \prod_{a_i\ge{0}}{m^{p\sum{a_i}}\cdot m^{\sum{a_ie_i}}}
*
\prod_{a_i<{0}}{m^{p\sum{a_i}}\cdot m^{\sum{a_ie_i}}}
\equiv 1 \pmod{n}
$$

两边同乘$\prod_{a_i<{0}}{m^{p\sum{-a_i}}\cdot m^{\sum{-a_ie_i}}}$

$$
\begin{aligned}
\prod{c_{i}^{a_i}}\equiv \prod_{a_i\ge{0}}{m^{p\sum{a_i}}\cdot m^{\sum{a_ie_i}}}

\equiv
\prod_{a_i<{0}}{m^{p\sum{-a_i}}\cdot m^{\sum{-a_ie_i}}} \pmod{n}
\end{aligned}
$$

移项

$$
\prod_{a_i\ge{0}}{m^{p\sum{a_i}}\cdot m^{\sum{a_ie_i}}}
-
\prod_{a_i<{0}}{m^{p\sum{-a_i}}\cdot m^{\sum{-a_ie_i}}} \pmod{n} \equiv 0 \pmod{n}
$$
即
$$
\prod_{a_i\ge{0}}{c_{i}^{a_i}}
-
\prod_{a_i<{0}}{c_{i}^{-a_i}}\equiv 0 \pmod{n}
$$
这样就找到了一开始说的同余式的形式。满足上面等式的$a_i$一定满足
- 1     $\sum{e_i*a_i} = 0$

- 2     $\sum{a_i}=0$

于是就可以构造格子

$$
L=
\left[\begin{array}{cccccc}
e_0 & 1 & 1 & 0 & \cdots & 0 & 0 \\
e_1 & 1 & 0 & 1 & \cdots & 0 & 0 \\
& \vdots & & &\ddots &  & \\
e_{62} & 1 & 0 & 0 & \cdots & 1 & 0 \\
e_{63} & 1 & 0 & 0 & \cdots & 0 & 1
\end{array}\right]
$$
>类似于背包问题的格，只不过背包问题中求解的向量只有0和1。

可以得到

$$
[a_0, a_1,\cdots,a_{62}, a_{63}]\cdot L=[0, 0,a_0, a_1,\cdots,a_{62}, a_{63}]
$$

由于我们要保证$[0,0, a_0, a_1, \cdots, a_{62}, a_{63}]$在格中足够小，并且可以找到多组$a_i$，可以在第一列和第二列乘一个大的系数。

```python
from sage.all import *

with open('output.txt') as f:
    es = eval(f.readline().strip())
    cs = eval(f.readline().strip())

L = matrix(es).T.augment(matrix([1]*len(es)).T)
L = L.augment(matrix.identity(len(es)))
L[:, 0] *= 2**512
L[:, 1] *= 2**512
L = L.LLL()

assert sum([a*e for a, e in zip(L[0][2:], es)]) == 0
assert sum([b*e for b, e in zip(L[1][2:], es)]) == 0
assert sum(L[0]) == 0
assert sum(L[1]) == 0
```

>实际上不只前两个向量满足等式，不过我们只需要两个$kn$就可以用gcd来恢复n了。

recover_n.py

```python
def get_kn(an):
    prod_p = 1
    prod_n = 1
    for i, a in enumerate(an):
        if a < 0:
            prod_n *= cs[i]**(-a)
        else:
            prod_p *= cs[i]**(a)
    return prod_p - prod_n


n1 = get_kn(L[0][2:])
n2 = get_kn(L[1][2:])

n = gcd(n1, n2)

for i in range(2, 300):
    while n % i == 0:
        n //= i 

print(n)
```
>可能是由于$a_i$比较接近的原因，在计算gcd后得到的n依然很大，但是通过遍历一些小的因数就可以得到真正的n



### Common Modulus Attack

在得到n后，再来看

$$
c_i\equiv m^{p+e_i}\equiv m^p\cdot m^{e_i}
$$
而且$m^p$是固定的，利用任意两组$c_i$就可以消去$m^p$

$$
\begin{aligned}
c_i\equiv m^p\cdot m^{e_i} \\
c_j\equiv m^p\cdot m^{e_j} \\
c^i\cdot c_j^{-1} \equiv m^{e_i-e_j} \pmod{n}
\end{aligned}
$$

只要找到两个互质的$e_i - e_j$就可以很轻松的得到flag

common_modulus_attack.py
```python
n = 17724789252315807248927730667204930958297858773674832260928199237060866435185638955096592748220649030149566091217826522043129307162493793671996812004000118081710563332939308211259089195461643467445875873771237895923913260591027067630542357457387530104697423520079182068902045528622287770023563712446893601808377717276767453135950949329740598173138072819431625017048326434046147044619183254356138909174424066275565264916713884294982101291708384255124605118760943142140108951391604922691454403740373626767491041574402086547023530218679378259419245611411249759537391050751834703499864363713578006540759995141466969230839

delta_e1 = es[1] - es[0]
for i in range(64):
    delta_e2 = es[i] - es[1]
    if delta_e2 > 0 and gcd(delta_e2, delta_e1) == 1:
        break
c1 = (cs[1] * inverse_mod(cs[0], n)) % n
c2 = (cs[i] * inverse_mod(cs[1], n)) % n

def attack(c1, c2, e1, e2):
    g, a, b = xgcd(e1, e2)
    if g != 1:
        return
    return power_mod(c1, a, n) * power_mod(c2, b, n) % n

m = attack(c1, c2, delta_e1, delta_e2)
from Crypto.Util.number import long_to_bytes
print(long_to_bytes(m))
```

flag: `hitcon{K33p_ev3rythIn9_1nd3p3ndent!}`

## 总结

整体复现下来，发现以前还是有很多细节没有弄懂，实际上很早之前就看过了maple师傅出的那道on_modulus，但是在hitcon的比赛中还有之前的N1CTF都没有用上。
