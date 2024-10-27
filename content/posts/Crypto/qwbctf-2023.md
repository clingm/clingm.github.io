---
title: Qwbctf 2023
date: 2023-12-22T15:06:27+08:00
mathjax: true
tags:
  - Crypto
description:
---


新一年的强网杯，但我还是一如既往的菜。

## not only rsa

```python
    from Crypto.Util.number import bytes_to_long
    from secret import flag
    import os
    
    n = 6249734963373034215610144758924910630356277447014258270888329547267471837899275103421406467763122499270790512099702898939814547982931674247240623063334781529511973585977522269522704997379194673181703247780179146749499072297334876619475914747479522310651303344623434565831770309615574478274456549054332451773452773119453059618433160299319070430295124113199473337940505806777950838270849
    e = 641747
    m = bytes_to_long(flag)
    
    flag = flag + os.urandom(n.bit_length() // 8 - len(flag) - 1)
    m = bytes_to_long(flag)
    
    c = pow(m, e, n)
    
    with open('out.txt', 'w') as f:
        print(f"{n = }", file=f)
        print(f"{e = }", file=f)
        print(f"{c = }", file=f)
    
```

源码很短，而且这个n可以直接在[factordb](http://factordb.com)里面查。发现是$p^5$的形式。继而计算$\\phi$, 但是发现和e不互素，而且e是其一个因子，那么方法就只能开根了。我在比赛中其实就想到了AMM + hensel-lifting的方法，但是我写的代码实在跑的太慢。赛后看了N1的WP感觉是sagemath polynomial的大幂数计算的原因🤣

我一开始写的代码
```python
    from Crypto.Util.number import *
    import sys
    sys.path.append("/home/tr0uble/CTF/tools/crypto-attacks/")
    from shared import rth_roots
    from sage.all import GF, ZZ, Zmod, inverse_mod
    from tqdm import tqdm
    
    n = 6249734963373034215610144758924910630356277447014258270888329547267471837899275103421406467763122499270790512099702898939814547982931674247240623063334781529511973585977522269522704997379194673181703247780179146749499072297334876619475914747479522310651303344623434565831770309615574478274456549054332451773452773119453059618433160299319070430295124113199473337940505806777950838270849
    e = 641747
    c = 730024611795626517480532940587152891926416120514706825368440230330259913837764632826884065065554839415540061752397144140563698277864414584568812699048873820551131185796851863064509294123861487954267708318027370912496252338232193619491860340395824180108335802813022066531232025997349683725357024257420090981323217296019482516072036780365510855555146547481407283231721904830868033930943
    
    p = 91027438112295439314606669837102361953591324472804851543344131406676387779969
    mps = list(rth_roots(GF(p), c % p, e))
    from Crypto.Util.number import *
    
    def hensel_lifting(f, p, k, m, r, method="drop"):
        assert m <= k, "m must less equal to k"
        pk = p ** k
        pm = p ** m
        fd = f.diff().change_ring(Zmod(pm))
        # print(fd)
        # print(fd.base_ring())
        assert fd(r) != 0, "The difference of polynomial on x must not equal to zero"
        # pn = pk * p
        f_ = f.change_ring(Zmod(pk*pm))
        # while f_(r) == 0:
        #     pn *= p
        #     f_ = f.change_ring(Zmod(pn))
        # if pn > pk*pm:
        #     return r
        # print(pn)
        t = -((int(f_(r)) // pk % pk) * int(fd(r).inverse())) % pm
        new_root = r + pk * t
        assert f.change_ring(Zmod(pk*pm))(new_root) == 0, "Can't to lifting"
        return new_root
    
    x = ZZ['x'].gen()
    f = x**e - c
    def hensel_lift5(r, p):
        for i in range(4):
            r = hensel_lifting(f, p, i+1, 1, r)
        return r
    for i in tqdm(range(len(mps))):
        ct = hensel_lift5(int(mps[i]), p)
        if b'flag' in long_to_bytes(ct):
            print(long_to_bytes(ct))
    
```
这个样子根本跑不动，在看了N1的WP后我也把polynomial改成普通的 `pow(r, e, p) - c` 的样子，代码变成
```python
def hensel(r):
        # lift to p^2
        d = e*pow(r, e-1, p) % p
        t = (-((pow(r, e, p**5)-c) // p) * inverse_mod(d, p)) % p
        r = r+t*p
        # lift to p^3
        d = e*pow(r, e-1, p) % p
        t = (-((pow(r, e, p**5)-c) // p**2) * inverse_mod(d, p)) % p
        r = r+t*p**2
        # lift to p^4
        d = e*pow(r, e-1, p) % p
        t = (-((pow(r, e, p**5)-c) // p**3) * inverse_mod(d, p)) % p
        r = r+t*p**3
        # lift to p^5
        d = e*pow(r, e-1, p) % p
        t = (-((pow(r, e, p**5)-c) // p**4) * inverse_mod(d, p)) % p
        r = r+t*p**4
        return r
    
    for i in tqdm(range(len(mps))):
        ct = hensel(int(mps[i]), p)
        if b'flag' in long_to_bytes(ct):
            print(long_to_bytes(ct))
```

这个版本的代码跑的飞快，并且在接近第40w个根的时候给出了答案。

## discrete log

```python
    from Crypto.Util.number import *
    from Crypto.Util.Padding import pad
    flag = 'flag{d3b07b0d416ebb}'
    
    assert len(flag) <= 45
    assert flag.startswith('flag{')
    assert flag.endswith('}')
    
    m = bytes_to_long(pad(flag.encode(), 128))
    
    p = 0xf6e82946a9e7657cebcd14018a314a33c48b80552169f3069923d49c301f8dbfc6a1ca82902fc99a9e8aff92cef927e8695baeba694ad79b309af3b6a190514cb6bfa98bbda651f9dc8f80d8490a47e8b7b22ba32dd5f24fd7ee058b4f6659726b9ac50c8a7f97c3c4a48f830bc2767a15c16fe28a9b9f4ca3949ab6eb2e53c3
    g = 5
    
    assert m < (p - 1)
    
    c = pow(g, m, p)
    
    with open('out.txt', 'w') as f:
        print(f"{p = }", file=f)
        print(f"{g = }", file=f)
        print(f"{c = }", file=f)
``` 

这题是一个纯dlp的题。已经知道flag的长度范围,而且告诉我们flag中的内容是hex，可以爆破flag长度，来得到大致的pad后的flag的形式，然后在爆破flag中的内容。可是flag最大有`((45 - 6 + 1) / 2)*8=160` bit需要爆破，明显是不可能的，所以需要优化的算法，选择空间换时间的MITM(Meet In The Middle)算法。

MITM可以将原来的复杂度减半，我们令$c = g^{h + x + padding}$，其中$h = “flag\\lbrace”$，$padding = “\\rbrace” + pad$, 然后我们把未知的x分为2个部分$x\_1,x\_2$。 $$ x\_1 = x\_{11} \\cdot 2^r \\\\ x = x\_1 + x\_2 $$

首先 $$ z = g^{x\_1 + x\_2} $$

然后爆破$x\_2$, 得到$z\_{2i} = g^{x\_{2i}}$，将$z\_{2i},x\_{2i}$间的映射保存起来$M\[z\_{2i}\] = x\_{2i}$

再爆破$x\_{11}$，得到$z\_{1i} = g^{x\_{1i}}$, 然后计算$z / z\_{1i}$在$M$中查表如果能找到就很大概率得到了正确的$x\_1,x\_2$
```python
    from Crypto.Util.number import getPrime, bytes_to_long, inverse
    from tqdm import tqdm
    p = 173383907346370188246634353442514171630882212643019826706575120637048836061602034776136960080336351252616860522273644431927909101923807914940397420063587913080793842100264484222211278105783220210128152062330954876427406484701993115395306434064667136148361558851998019806319799444970703714594938822660931343299
    g = 5
    c = 105956730578629949992232286714779776923846577007389446302378719229216496867835280661431342821159505656015790792811649783966417989318584221840008436316642333656736724414761508478750342102083967959048112859470526771487533503436337125728018422740023680376681927932966058904269005466550073181194896860353202252854
    
    for flag_len in range(16, 45, 2):
        print(f"trying flag length = {flag_len}")
        unknown_len = flag_len - 6
        pad_len = 128 - flag_len
        padding = bytes([pad_len]) * pad_len
        a = pow(g, bytes_to_long(b"flag{" + b"\x00"*(unknown_len - 1) + b"}" + padding), p)
        cc = c * inverse(a, p) % p
    
        l = {}
        for i in tqdm(range(16 ** (unknown_len // 2 + 1))):
            x = pow(g, bytes_to_long(hex(i)[2:].rjust(unknown_len//2 + 1, '0').encode()), p)
            l[x] = i
        
        for i in tqdm(range(16 ** (unknown_len // 2 - 1))):
            y = pow(g, bytes_to_long(hex(i)[2:].rjust(unknown_len//2 - 1, '0').encode()), p)
            y = cc * inverse(pow(y, pow(2, unknown_len//2 + 1 + pad_len + 1), p), p) % p
            if y in l.keys():
                print(hex(i)[2:], hex(l[y])[2:])
```

## babyrsa

```python
    from Crypto.Util.number import isPrime, inverse, bytes_to_long
    from random import getrandbits, randrange
    from collections import namedtuple
    
    
    Complex = namedtuple("Complex", ["re", "im"])
    
    def complex_mult(c1, c2, modulus):
        return Complex(
            (c1.re * c2.re - c1.im * c2.im) % modulus,
            (c1.re * c2.im + c1.im * c2.re) % modulus,
        )
    
    def complex_pow(c, exp, modulus):
        result = Complex(1, 0)
        while exp > 0:
            if exp & 1:
                result = complex_mult(result, c, modulus)
            c = complex_mult(c, c, modulus)
            exp >>= 1
        return result
    
    def rand_prime(nbits, kbits, share):
        while True:
            p = (getrandbits(nbits) << kbits) + share
            if p % 4 == 3 and isPrime(p):
                return p
    
    def gen():
        while True:
            k = getrandbits(100)
            pp = getrandbits(400) << 100
            qq = getrandbits(400) << 100
            p = pp + k
            q = qq + k
            if isPrime(p) and isPrime(q):
                break
        if q > p:
            p, q = q, p
    
        n = p * q
        lb = int(n ** 0.675)
        ub = int(n ** 0.70)
        while True:
            d = randrange(lb, ub)
            try:
                e = inverse(d, (p * p - 1) * (q * q - 1))
                break
            except:
                continue
        sk = (p, q, d)
        pk = (n, e)
        return pk, sk
    
    
    pk, sk = gen()
    n, e = pk
    with open("flag.txt", "rb")as f:
        flag = f.read()
    
    m = Complex(bytes_to_long(flag[:len(flag)//2]), bytes_to_long(flag[len(flag)//2:]))
    c = complex_pow(m, e, n)
    print(f"n = {n}")
    print(f"e = {e}")
    print(f"c = {c}")
```

首先肯定是要分解n的，然后看到这个密钥生成的过程想到了去年的RCTF和HFCTF, 过程十分相似，只是这是share lsb, 使用那篇文章的方法行不通，赛后发现还有论文[A new attack on some RSA variants](https://www.sciencedirect.com/science/article/pii/S0304397523002116)，论文里有一个例子参数都一样的，照着实现就好了。
```python
    from collections import namedtuple
    from sage.all import ZZ, QQ, Mod, PolynomialRing, isqrt, matrix
    import time
    from Crypto.Util.number import inverse, long_to_bytes
    
    Complex = namedtuple("Complex", ["re", "im"])
    
    n=5527823687914629445928751931351501568538008375615524908427389726990389715275837002861651510701228393924757035291457877675111540404203012135378834487753490236754111855821567310395547714573242118176027909363197756783356599319622032729503900145504768199117956830109488213721179197298976559379295734300889
    e=16021660724557845861903926629189678508104614030647584377887691761323265228729978577912718772018351305060755997181165548896287262237118067747095895135689542315518542722282213749507552545174880598816723954290814011885379391990414696263834518312117922281210824958741501122210535644121406075221738197619232462600078762156908163867986801571665710762394459236886966450990535704563963180305912668319246133004743587146218547017334946743812609663005378905656444984371409043041484148339572240945472316645060906808117473860228212000852669342881620738498172046794549032176677232076775574888980921634064269760730733
    c = Complex(re=2012948531808535658618135982376157338497630873224229514232396588630318374103303632458672435554153057032250931230752901501660055660862099702318326352000431226866382254438987809465982480745411398406968025077723685872358629823751506867202963276004837767911659230345188497115504371022168504350112757911970, im=381189254885346479441224149330737027827963006108977158894650476797604540263935003393925783161307886586032523860105464648325293157866129992025717767014563299764845263099980532235028862005360622884509996726485571556604386339566439967304706464942491349381908685406278617323955301845117990230102559034276)
    
    def attack2(N, e, m, t, X, Y):
        ti=time.time()
        PR = PolynomialRing(QQ, 'x,y', 2, order='lex')
        x, y = PR.gens()
        F = x*y**2 + a1*x*y + a2*x + a3
    
        G_polys = []
        # G_{k,i_1,i_2}(x,y) = x^{i_1-k}y_{i_2-2k}f(x,y)^{k}e^{m-k} 
        for k in range(m + 1):
            for i_1 in range(k, m+1):
                for i_2 in [2*k, 2*k + 1]:
                    G_polys.append(x**(i_1-k) * y**(i_2-2*k) * F**k * e**(m-k))
    
        H_polys = []
        # y_shift H_{k,i_1,i_2}(x,y) = y^{i_2-2k} f(x,y)^k e^{m-k}
        for k in range(m + 1):
            for i_2 in range(2*k+2, 2*k+t+1):
                H_polys.append(y**(i_2-2*k) * F**k * e**(m-k))
    
        polys = G_polys + H_polys
        monomials = []
        for poly in polys:
            monomials.append(poly.lm())
        
        dims1 = len(polys)
        dims2 = len(monomials)
        MM = matrix(QQ, dims1, dims2)
        for idx, poly in enumerate(polys):
            for idx_, monomial in enumerate(monomials):
                if monomial in poly.monomials():
                    MM[idx, idx_] = poly.monomial_coefficient(monomial) * monomial(X, Y)
        print(f"LLL dimension: {MM.nrows()}x{MM.ncols()}")
        B = MM.LLL()
        found_polynomials = False
    
        for pol1_idx in range(B.nrows()):
            for pol2_idx in range(pol1_idx + 1, B.nrows()):
                P = PolynomialRing(QQ, 'a,b', 2)
                a, b = P.gens()
                pol1 = pol2 = 0
                for idx_, monomial in enumerate(monomials):
                    pol1 += monomial(a,b) * B[pol1_idx, idx_] / monomial(X, Y)
                    pol2 += monomial(a,b) * B[pol2_idx, idx_] / monomial(X, Y)
    
                # resultant
                rr = pol1.resultant(pol2)
                # are these good polynomials?
                if rr.is_zero() or rr.monomials() == [1]:
                    continue
                else:
                    print(f"found them, using vectors {pol1_idx}, {pol2_idx}")
                    found_polynomials = True
                    break
            if found_polynomials:
                break
    
        if not found_polynomials:
            print("no independant vectors could be found. This should very rarely happen...")
    
    
        PRq = PolynomialRing(QQ, 'z')
        z = PRq.gen()
        rr = rr(z, z)
        soly = rr.roots()[0][0]
    
        ppol = pol1(z, soly)
        solx = ppol.roots()[0][0]
        return solx, soly
    
    # print(f"n={n}\ne={e}")
    r = 100
    alpha = ZZ(e).nbits() / ZZ(n).nbits()
    beta = r / ZZ(n).nbits()
    delta = 0.70
    print(alpha, beta, delta)
    u0 = ZZ(Mod(n, 2**r).nth_root(2, all=True)[0])
    v0 = ZZ((2*u0 + (n - u0**2)*inverse(u0, 4**r)) % (4**r))
    print(u0, v0)
    a1 = int(v0 * inverse(2**(2*r - 1), e) % e)
    a2 = int(-((n+1)**2 - v0**2) * inverse(2**(4*r), e) % e)
    a3 = int(-inverse(2**(4*r), e) % e)
    X = ZZ(2*n**(alpha + delta - 2))
    Y = ZZ(3*n**(0.5 - 2*beta))
    
    k, v = map(int, attack2(n, e, 4, 4, X, Y))
    p_plus_q = int(2**(2*r)*v + v0)
    p_minus_q = isqrt(p_plus_q**2 - 4*n)
    
    p = (p_minus_q + p_plus_q) // 2
    q = n // p
    print(f"p = {p}")
    print(f"q = {q}")
    print(p*q == n)
    
    p = 2909361750718925654806263886008919952754040081505772293312305999147201945140177280651101936712818375809233132556289477012051690455667963261726156542693
    q = 1900012498118758080386063557941332201661823681127196909513390375685272680057296393801682140714541517469250351359374711900794251164879414119839995155173
    
    def complex_mult(c1, c2, modulus):
        return Complex(
            (c1.re * c2.re - c1.im * c2.im) % modulus,
            (c1.re * c2.im + c1.im * c2.re) % modulus,
        )
    
    def complex_pow(c, exp, modulus):
        result = Complex(1, 0)
        while exp > 0:
            if exp & 1:
                result = complex_mult(result, c, modulus)
            c = complex_mult(c, c, modulus)
            exp >>= 1
        return result
    
    d = inverse(e, (p**2 - 1)*(q**2 - 1))
    m = complex_pow(c, d, n)
    print(long_to_bytes(m.re) + long_to_bytes(m.im))
```
