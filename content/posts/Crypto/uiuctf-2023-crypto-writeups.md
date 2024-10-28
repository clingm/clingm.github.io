---
title: UIUCTF 2023 Crypto WriteUps
date: 2023-07-04T15:27:00+08:00
mathjax: true
tags:
  - Crypto
description: 
toc: true
---



这次用IKUN为ID打了UIUCTF，解了全部的密码题，都挺简单的。

Three-Time-Pad
==============

通过题目描述就知道是One-Time-Pad的key reuse。而且给了一个明密文对，xor一下就得到key，然后去解其他的明文就可以了

    from Crypto.Util.strxor import strxor
    
    c1 = open('Three-Time Pad/c1', 'rb').read()
    c2 = open('Three-Time Pad/c2', 'rb').read()
    c3 = open('Three-Time Pad/c3', 'rb').read()
    p2 = open('Three-Time Pad/p2', 'rb').read()
    
    key = strxor(c2 ,p2)
    print(key)
    print(strxor(key[:len(c3)], c3[:len(key)]))
    

Morphing Time
=============

    #!/usr/bin/env python3
    from Crypto.Util.number import getPrime
    from random import randint
    
    with open("/flag", "rb") as f:
        flag = int.from_bytes(f.read().strip(), "big")
    
    
    def setup():
        # Get group prime + generator
        p = getPrime(512)
        g = 2
    
        return g, p
    
    
    def key(g, p):
        # generate key info
        a = randint(2, p - 1)
        A = pow(g, a, p)
    
        return a, A
    
    
    def encrypt_setup(p, g, A):
        def encrypt(m):
            k = randint(2, p - 1)
            c1 = pow(g, k, p)
            c2 = pow(A, k, p)
            c2 = (m * c2) % p
    
            return c1, c2
    
        return encrypt
    
    
    def decrypt_setup(a, p):
        def decrypt(c1, c2):
            m = pow(c1, a, p)
            m = pow(m, -1, p)
            m = (c2 * m) % p
    
            return m
    
        return decrypt
    
    
    def main():
        print("[$] Welcome to Morphing Time")
    
        g, p = 2, getPrime(512)
        a = randint(2, p - 1)
        A = pow(g, a, p)
        decrypt = decrypt\_setup(a, p)
        encrypt = encrypt\_setup(p, g, A)
        print("[$] Public:")
        print(f"[$]     {g = }")
        print(f"[$]     {p = }")
        print(f"[$]     {A = }")
    
        c1, c2 = encrypt(flag)
        print("[$] Eavesdropped Message:")
        print(f"[$]     {c1 = }")
        print(f"[$]     {c2 = }")
    
        print("[$] Give A Ciphertext (c1\_, c2\_) to the Oracle:")
        try:
            c1\_ = input("[$]     c1_ = ")
            c1_ = int(c1_)
            assert 1 < c1_ < p - 1
    
            c2_ = input("[$]     c2\_ = ")
            c2\_ = int(c2\_)
            assert 1 < c2\_ < p - 1
        except:
            print("!! You've Lost Your Chance !!")
            exit(1)
    
        print("[$] Decryption of You-Know-What:")
        m = decrypt((c1 * c1_) % p, (c2 * c2_) % p)
        print(f"[$]     {m = }")
    
        # !! NOTE !!
        # Convert your final result to plaintext using
        # long\_to\_bytes
    
        exit(0)
    
    
    if \_\_name\_\_ == "\_\_main\_\_":
        main()
    

题目先生成一个密文对(c1, c2)，然后我们再提供另一个密文对(c1\\_, c2\\_)，最后解密(c1\*c1\\_, c2\*c2\\_)。这个加密其实具有同态的性质，$D(E(m1_m2))=m1_m2$，我的方法是把(c1\\_, c2\\_)=(c1, c2)，发送过去，decrypt结果开根号

    # from pwn import *
    from Crypto.Util.number import inverse ,long\_to\_bytes
    from CryptoAttack.shared import rth\_roots
    from sage.all import GF
    
    g = 2
    p = 13289347032516231009959348011430148283411927647172578284071703227889894922514134893631970157231909150815454707711932241133170120482265709066674051861579843
    
    m = 761496468773376761795899352752891529822073231628988751627659046277114210905520809413615009126941230164268704121097232388839092860182037274585600956458729
    m = rth\_roots(GF(p), m, 2) # AMM
    for m\_ in m:
        print(long\_to\_bytes(int(m\_)))
    

At Home
=======

    from Crypto.Util.number import getRandomNBitInteger
    
    flag = int.from\_bytes(b"uiuctf{******************}", "big")
    
    a = getRandomNBitInteger(256)
    b = getRandomNBitInteger(256)
    a\_ = getRandomNBitInteger(256)
    b\_ = getRandomNBitInteger(256)
    
    M = a * b - 1
    e = a\_ * M + a
    d = b\_ * M + b
    
    n = (e * d - 1) // M
    
    c = (flag * e) % n
    
    print(f"{e = }")
    print(f"{n = }")
    print(f"{c = }")
    

没太看懂在干什么，最后也不是一个RSA，而是乘法，求逆再乘回去就ok

    from Crypto.Util.number import inverse, long\_to\_bytes
    
    e = 359050389152821553416139581503505347057925208560451864426634100333116560422313639260283981496824920089789497818520105189684311823250795520058111763310428202654439351922361722731557743640799254622423104811120692862884666323623693713
    n = 26866112476805004406608209986673337296216833710860089901238432952384811714684404001885354052039112340209557226256650661186843726925958125334974412111471244462419577294051744141817411512295364953687829707132828973068538495834511391553765427956458757286710053986810998890293154443240352924460801124219510584689
    c = 67743374462448582107440168513687520434594529331821740737396116407928111043815084665002104196754020530469360539253323738935708414363005373458782041955450278954348306401542374309788938720659206881893349940765268153223129964864641817170395527170138553388816095842842667443210645457879043383345869
    
    d = inverse(e, n)
    print(long\_to\_bytes(c * d % n))
    

Group Project
=============

    from Crypto.Util.number import getPrime, long\_to\_bytes
    from random import randint
    import hashlib
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import pad
    
    
    with open("/flag", "rb") as f:
        flag = f.read().strip()
    
    def main():
        print("[$] Did no one ever tell you to mind your own business??")
    
        g, p = 2, getPrime(1024)
        a = randint(2, p - 1)
        A = pow(g, a, p)
        print("[$] Public:")
        print(f"[$]     {g = }")
        print(f"[$]     {p = }")
        print(f"[$]     {A = }")
    
        try:
            k = int(input("[$] Choose k = "))
        except:
            print("[$] I said a number...")
    
        if k == 1 or k == p - 1 or k == (p - 1) // 2:
            print("[$] I'm not that dumb...")
    
        Ak = pow(A, k, p)
        b = randint(2, p - 1)
        B = pow(g, b, p)
        Bk = pow(B, k, p)
        S = pow(Bk, a, p)
    
        key = hashlib.md5(long\_to\_bytes(S)).digest()
        cipher = AES.new(key, AES.MODE\_ECB)
        c = int.from\_bytes(cipher.encrypt(pad(flag, 16)), "big")
    
        print("[$] Ciphertext using shared 'secret' ;)")
        print(f"[$]     {c = }")
    
    
    if \_\_name\_\_ == "\_\_main\_\_":
        main()
    

一个DHKE的结构，只不过share secret等于$A^{bk}$或者$B^{ak}$，k是我们提供的，而且题目对k的限制很少，直接k=0就能让S=1

    import hashlib
    from Crypto.Cipher import AES
    from Crypto.Util.number import long\_to\_bytes
    from Crypto.Util.Padding import pad, unpad
    
    """
    == proof-of-work: disabled ==
    [$] Did no one ever tell you to mind your own business??
    [$] Public:
    [$]     g = 2
    [$]     p = 158933544127552408487948447807428463957712902924993414361606315291355411607384367996376354677736850611849295691602338202271436191522788215424033532031016251368132902230725941540023377059768550595786440405122556015339428099356622585449529496898921056593083633185019451806177861078575994409263138733687068792799
    [$]     A = 138080236095090357741465441539844252236292412086123875229070537933312716089238736277365578028994205565624594997738689890489288528423427109453010552946082233967709353164128285353660359107004142666114197261146149640413525640563236734912196009669781288700371091278944420971369686148726366317785579928283502366105
    [$] Choose k = 0
    [$] I said a number...
    [$] Ciphertext using shared 'secret' ;)
    [$]     c = 31383420538805400549021388790532797474095834602121474716358265812491198185235485912863164473747446452579209175051706
    """
    
    S = 1
    key = hashlib.md5(long_to_bytes(S)).digest()
    cipher = AES.new(key, AES.MODE_ECB)
    c = 31383420538805400549021388790532797474095834602121474716358265812491198185235485912863164473747446452579209175051706
    flag = unpad(cipher.decrypt(bytes.fromhex(hex(c)[2:])), 16)
    print(flag)
    

Group Projection
================

Group Project 的revenge，增加了k的限制。利用Fermat’s Little Theorem，另k = (p-1)/n，$S = (g^{a\*b/n})^{p-1}=1\\ mod\\ p$，

n不等于2就行。

    import hashlib
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import unpad
    from Crypto.Util.number import long_to_bytes
    
    p = 139032757636222313123916481279659256633800514133158858970518545479864202513956909120032104329169518246523507727129626628147424337775402552248291802990904374347483839307810082951263117806443660098619760901849079084449360763684208244559438743603441370419864656604839651222027408170130161288175607706415987339951
    g = 2
    
    for n in range(3, 100):
        if (p-1) % n == 0:
            break
    
    k = (p-1) // n
    print(k)
    
    """
    ❯ nc group-projection.chal.uiuc.tf 1337
    == proof-of-work: disabled ==
    [$] Did no one ever tell you to mind your own business??
    [$] Public:
    [$]     g = 2
    [$]     p = 139032757636222313123916481279659256633800514133158858970518545479864202513956909120032104329169518246523507727129626628147424337775402552248291802990904374347483839307810082951263117806443660098619760901849079084449360763684208244559438743603441370419864656604839651222027408170130161288175607706415987339951
    [$]     A = 48424906204657400801910391587723073820889963849588162859914929640578125651068264575804467000640427823761662066267461432811984544794882016217496954537189602621958326062644811395697361082308190962645285374199972086004175760198693820984667418927396709157066284655086846680816750267810295215235380908588830891756
    [$] Choose k = 27806551527244462624783296255931851326760102826631771794103709095972840502791381824006420865833903649304701545425925325629484867555080510449658360598180874869496767861562016590252623561288732019723952180369815816889872152736841648911887748720688274083972931320967930244405481634026032257635121541283197467990
    [$] Ciphertext using shared 'secret' ;)
    [$]     c = 1691944695724849293926275726240861374800996311184132393897728962707265220226723293525972802888619688288935711977380618166473780964359689471413732581132986
    """
    c = 1691944695724849293926275726240861374800996311184132393897728962707265220226723293525972802888619688288935711977380618166473780964359689471413732581132986
    S = 1
    key = hashlib.md5(long_to_bytes(S)).digest()
    cipher = AES.new(key, AES.MODE_ECB)
    c = 31383420538805400549021388790532797474095834602121474716358265812491198185235485912863164473747446452579209175051706
    flag = unpad(cipher.decrypt(bytes.fromhex(hex(c)[2:])), 16)
    print(flag)
    

crack\_the\_safe
================

    from Crypto.Cipher import AES
    from secret import key, FLAG
    
    p = 4170887899225220949299992515778389605737976266979828742347
    ct = bytes.fromhex("ae7d2e82a804a5a2dcbc5d5622c94b3e14f8c5a752a51326e42cda6d8efa4696")
    
    def crack_safe(key):
        return pow(7, int.from_bytes(key, 'big'), p) == 0x49545b7d5204bd639e299bc265ca987fb4b949c461b33759
    
    assert crack_safe(key) and AES.new(key,AES.MODE_ECB).decrypt(ct) == FLAG
    

源码很短，是一个纯dlp题。首先分析阶

    factor(p-1)
    >>> [2, 19, 151, 577, 67061, 18279232319, 111543376699, 9213409941746658353293481]
    

最后一个子群的阶比较大，用sage的discrete\_log解不出来。但是有比discrete\_log更好的工具,[cado-nfs](https://gitlab.inria.fr/cado-nfs/cado-nfs)，这个工具是对Number Field Sieve算法的实现，而且这个算法可以用来解决$F\_p$的dlp问题。

    > ./cado-nfs.py -dlp -ell 9213409941746658353293481 target=1798034623618994974454756356126246972179657041628028417881 4170887899225220949299992515778389605737976266979828742347
    Info:root: If you want to compute one or several new target(s), run ./cado-nfs.py /tmp/cado.qp06_hic/p60.parameters_snapshot.0 target=<target>[,<target>,...]
    Info:root: logbase = 689700230313623370222183478814904246546188182712829892313
    Info:root: target = 1798034623618994974454756356126246972179657041628028417881
    Info:root: log(target) = 2215765705042274080663116 mod ell
    2215765705042274080663116
    

    > ./cado-nfs.py -dlp -ell 9213409941746658353293481 target=7 4170887899225220949299992515778389605737976266979828742347
    Info:root: If you want to compute one or several new target(s), run ./cado-nfs.py /tmp/cado.fi1xc74t/p60.parameters_snapshot.0 target=<target>[,<target>,...]
    Info:root: logbase = 689700230313623370222183478814904246546188182712829892313
    Info:root: target = 7
    Info:root: log(target) = 6424341129540508417798214 mod ell
    6424341129540508417798214
    

最后CRT得到key

    from sage.all import factor, discrete_log, GF, CRT_list
    from Crypto.Util.number import inverse
    from Crypto.Cipher import AES
    
    p = 4170887899225220949299992515778389605737976266979828742347
    ct = bytes.fromhex("ae7d2e82a804a5a2dcbc5d5622c94b3e14f8c5a752a51326e42cda6d8efa4696")
    # pow(7, int.from_bytes(key, 'big'), p) == 0x49545b7d5204bd639e299bc265ca987fb4b949c461b33759
    A = 0x49545b7d5204bd639e299bc265ca987fb4b949c461b33759
    
    g = 7
    
    fac = factor(p-1)
    sub_orders = list(map(lambda x: x[0]**x[1], fac))
    ell = sub_orders[-1]
    
    print("[+] dlp infomation:")
    print(f"     {p = }")
    print(f"     {g = }")
    print(f"     {A = }")
    print(f"     {sub_orders = }")
    print(f"     {ell = }")
    
    xi = []
    for p_i, e_i in fac[:-1]:
        r = (p-1) // (p_i**e_i)
        
        x = discrete_log(pow(A, r, p), GF(p)(pow(g, r, p)), ord=p_i**e_i)
        xi.append(x)
    
    """
    Info:root: logbase = 689700230313623370222183478814904246546188182712829892313
    Info:root: target = 1798034623618994974454756356126246972179657041628028417881
    Info:root: log(target) = 2215765705042274080663116 mod ell
    2215765705042274080663116
    
    Info:root: logbase = 689700230313623370222183478814904246546188182712829892313
    Info:root: target = 7
    Info:root: log(target) = 6424341129540508417798214 mod ell
    6424341129540508417798214
    """
    
    log_h = 2215765705042274080663116
    log_g = 6424341129540508417798214
    
    x = log_h * inverse(log_g, ell) % ell
    xi.append(x)
    
    print(f"[+] dlp result:")
    print(f"    {xi = }")
    X = CRT_list(xi, sub_orders)
    print(f"    {X = }")
    print(f"    is solved = {pow(g, X, p) == A}")
    
    def crack_safe(key):
        return pow(7, int.from_bytes(key, 'big'), p) == 0x49545b7d5204bd639e299bc265ca987fb4b949c461b33759
    key = bytes.fromhex(hex(X)[2:])
    assert crack_safe(key)
    
    ct = bytes.fromhex("ae7d2e82a804a5a2dcbc5d5622c94b3e14f8c5a752a51326e42cda6d8efa4696")
    print(AES.new(key,AES.MODE_ECB).decrypt(ct))
    
