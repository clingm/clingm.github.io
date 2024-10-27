---
title: Breaking Ecdsa From Nonce Bits
date: 2022-11-22T15:48:05+08:00
mathjax: true
tags:
  - Crypto
description:
---



> 如果对HNP不太了解，可以先看一下我的另一篇文章[HNP](https://clingm.github.io/2022/11/18/Hidden-Number-Problem/)

Preview
-------

先简单回顾一下HNP和ECDSA。

**Hidden Number problem（HNP）** ：有一个对外保密的数$\\alpha$和对外公开的模数$n$。随机的选择$t\_i$计算$s\_i=\\alpha t\_i\\ mod\\ n$，并且泄漏出$s\_i$的最高有效位，就可以利用$CVP$的方法去恢复$\\alpha$。

**ECDSA** ：在有限域$\\mathbb{F}p$上选择椭圆曲线$E\\left(\\mathbb{F}\_{p}\\right)$，以及阶为$n$的子群的基点$G$。私钥为$0\\leq d < n$，公钥为$dG=Q$。 签名：

*   选择nonce为随机数$k$
*   计算明文的$hash$，$h=Hash(m)$
*   计算$r=(kG)\_x$，x表示$kG$的x坐标
*   计算$s = k^{-1} \\cdot (h+d\\cdot r)\\ mod\\ n$
*   签名为$(r, s)$

ECDSA as a HNP
--------------

由ECDSA的签名过程，重写一下公式。

$$ -s^{-1}\\cdot h + k\\equiv s^{-1}\\cdot r \\cdot d \\pmod{n} $$

与HNP问题对应一下，令

$$ \\begin{aligned} \\alpha=d \\\\ t\_i=s^{-1}\\cdot r \\\\ a\_i = s^{-1}\\cdot h \\end{aligned} $$

由于nonce相较于$a\_i$来说较小，所以

$$ \\begin{aligned} MSB\_{\\alpha,k}(t\_i) &= MSB\_k(\\alpha \\cdot t\_i\\ mod\\ n) \\\\ &= MSB\_k(d\\cdot s^{-1}\\cdot r) \\\\ &= MSB\_k(-a\_i + k) \\\\ &= n-a\_i \\end{aligned} $$

Solving the HNP with lattices
-----------------------------

在之前讲的HNP中，Boneh and Venkatesan给出了这样的格

$$ \\left\[\\begin{array}{cccccc} n & 0 & 0 & \\cdots & 0 & 0 \\\\ 0 & n & 0 & \\cdots & 0 & 0 \\\\ & \\vdots & & & \\cdots & \\\\ 0 & 0 & 0 & \\cdots & n & 0 \\\\ t\_{0} & t\_{1} & t\_{2} & \\cdots & t\_{m-1} & 1 / n \\end{array}\\right\] $$

但是在后来的研究中Kannan给出了改进后的格

$$ \\left\[\\begin{array}{ccccccc} n & 0 & 0 & \\cdots & 0 & 0 & 0 \\\\ 0 & n & 0 & \\cdots & 0 & 0 & 0 \\\\ & \\vdots & & & \\vdots & & \\\\ 0 & 0 & 0 & \\cdots & n & 0 & 0 \\\\ t\_{0} & t\_{1} & t\_{2} & \\cdots & t\_{m-1} & 2^{\\ell} / n & 0 \\\\ a\_{0} & a\_{1} & a\_{2} & \\cdots & a\_{m-1} & 0 & 2^{\\ell} \\end{array}\\right\] $$

> $\\ell$是nonce的位长度，$2^{\\ell}$就是nonce的上界。

在这个格中存在一个向量

$$ v\_k=\\left(k\_{0}, k\_{1}, \\ldots, k\_{m-1}, 2^{\\ell} \\cdot \\alpha / n, 2^{\\ell}\\right) $$

> 用到数第二行向量乘$\\alpha$加上最后一行，$t\_i\\alpha+a\_i=-a\_i+k\_i+a\_i=k\_i$。

这个向量在格中是很短的。它的模$||vk|| \\leq \\sqrt{m+2}\\cdot 2^{\\ell}$。但是格中还有一个更短的向量

$$ (0, 0, \\cdots,0, 2^{\\ell}, 0) $$

所以在利用LLL算法之后，要找的向量并不再第一行。

Example & Demo
--------------

    from sage.all import *
    from hashlib import sha1
    import time
    
    
    # use secp128r1 curve to test
    # The parameters:
    _p = 0xfffffffdffffffffffffffffffffffff
    _b = 0xe87579c11079f43dd824993c2cee5ed3
    _a = -0x3
    _Gx = 0x161ff7528b899b2d0c28607ca52c5b86
    _Gy = 0xcf5ac8395bafeb13c02da292dded7a83
    order = 340282366762482138443322565580356624661
    E = EllipticCurve(GF(_p), [_a, _b])
    G = E(_Gx, _Gy)
    
    # The Lattice attack paramters
    # n = ceil(log(order, 2))
    # k = ceil(sqrt(n)) + ceil(log(n, 2))
    # print(f"The number of significant bits = {k}")
    # m = 2*ceil(sqrt(n))
    m = 24
    print(f"about {m} signatures")
    
    
    # Ecdsa sign Algorithm
    def EcdsaSign(number, k):
        r = ZZ((k*G)[0])
        s = (inverse_mod(k, order) * (number + d*r)) % order
        return (ZZ(r), ZZ(s))
    
    # This function is not used in this test
    def string_to_number(str_msg:str, hash:callable):
        """parameters:
        str_msg: the massage be converted to number
        hash: callable hash function
        """
        return int(hash(str_msg.encode()).hexdigest(), 16)
    
    def generator():
        """Return a_i , t_i , msb, h
        a_i = s^(-1) * h
        t_i = s^(-1) * r
        msb = -a_i % order
        h: the message to be signed
        """
        h = randint(0, 2**128) % order
        k = randint(1, 2**120) % order
    
        r, s = EcdsaSign(h, k)
    
        a_i = (inverse_mod(s, order) * h) % order
        t_i = (inverse_mod(s, order) * r) % order
    
        return t_i, a_i, -a_i % order, h
    
    
    ## Solving the HNP with Boneh and Venkatesan's lattice
    def build_basis(oracle_inputs):
        """Returns a basis using the HNP game parameters and inputs to our oracle
        """
        basis_vectors = []
        for i in range(m):
            p_vector = [0] * (m+1)
            p_vector[i] = order
            basis_vectors.append(p_vector)
        basis_vectors.append(list(oracle_inputs) + [QQ(1)/QQ(order)])
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
    
    def Boneh_Venkatesan_method():
        # print("[+] using Boneh and Venkatesan's method to recover the private key")
        inputs = []
        answers = []
        for _ in range(m):
            t_i, a_i, msb, h = generator()
            inputs.append(t_i)
            answers.append(msb)
    
        time0 = time.time()
        lattice = build_basis(inputs)
        u = vector(ZZ, list(answers) + [0])
        v = approximate_closest_vector(lattice, u)
    
        recovered_alpha = (v[-1] * order) % order
    
        spend = time.time() - time0
        # print("spend %.3fs" % spend)
    
        # assert recovered_alpha == d
        if recovered_alpha == d:
            # print("Recovered alpha! Alpha is %d" % recovered_alpha)
            return 1, spend
        else:
            # print("fault to recover!")
            return 0, spend
    
        
    
    
    def build_Kannan_basis(t_i, a_i):
        """Returns a basis using the HNP game parameters and inputs to our oracle
        """
        basis_vectors = []
        for i in range(m):
            p_vector = [0] * (m+2)
            p_vector[i] = order
            basis_vectors.append(p_vector)
        basis_vectors.append(list(t_i) + [QQ(2**120)/QQ(order)] + [0])
        basis_vectors.append(list(a_i) + [0] + [QQ(2**120)])
        return Matrix(QQ, basis_vectors)
    
    def Kannan_method():
        # print("\n[+] using Kannan's method to recover the private key")
        inputs = []
        answers = []
        hs = []
        for _ in range(m):
            t_i, a_i, msb, h = generator()
            inputs.append(t_i)
            answers.append(a_i)
            hs.append(h)
        
        time0 = time.time()
        lattice = build_Kannan_basis(inputs, answers)
        # print("Solving SVP using lattice with basis:\n%s\n" % str(lattice))
        L = lattice.LLL()
        # print(L)
        ks = L[1]
    
        spend = time.time() - time0
        # print("spend %.3fs" % spend)
    
        if (-answers[0] + ZZ(ks[0])) % order == (inputs[0] * d) % order:
            # print(f"Recovered nonce! {ks}")
            recovered_d = ( (-answers[0] + ZZ(ks[0])) * inverse_mod(inputs[0], order) ) % order
            assert recovered_d == d
            # print("Recovered private key! private key is %d" % recovered_d)
            return 1, spend
        else:
            # print("fault to recover!")
            return 0, spend
        
    
    if __name__ == "__main__":
        method1_spend = []
        method1_success = 0
        method2_spend = []
        method2_success = 0
    
        for _ in range(20):
            d = randint(1, order-1)
            # print(f"the privet key is {d}")
            pubkey = d*G
    
            flag0, spend0 = Boneh_Venkatesan_method()
            flag1, spend1 = Kannan_method()
    
            method1_success += flag0
            method2_success += flag1
            method1_spend.append(spend0)
            method2_spend.append(spend1)
        
        print("[+] Boneh_Venkatesan_method:")
        print(f"successed: {method1_success}/20\ntime spend: {sum(method1_spend)/20}")
        print("[+] Kannan_method:")
        print(f"successed: {method2_success}/20\ntime spend: {sum(method2_spend)/20}")
    

### test result

*   当k的位数很小，比如只有几十位长甚至几位长，然后调小m，会发现Boneh\_Venkatesan\_method和Kannan\_method的时间相差不大，但是前者的正确率更高。
    
*   当k的位数比较大，比如有一百多甚至一百二十多，为了保证正确率需要调大m，这个时候Kannan\_method的正确率以及速度都比Boneh\_Venkatesan\_method要表现的好。
    

> 当然我这里只是20次为一组，测试结果肯定是不太准确的。

Reference
---------

*   On Bounded Distance Decoding with Predicate: Breaking the “Lattice Barrier” for the Hidden Number Problem by Martin R. Albrecht and Nadia Heninger
*   [Intended Solution to NHP in GxzyCTF 2020](https://blog.soreatu.com/posts/intended-solution-to-nhp-in-gxzyctf-2020/#writeup) by Soreat\_u

