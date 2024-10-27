---
title: 近期比赛的复现
date: 2023-07-16T15:24:01+08:00
mathjax: true
tags:
  - Crypto
description:
---


好久没写blog了。。复现一下最近的比赛

Crypto CTF 2023
===============

Medium
------

### blobfish

    #!/usr/bin/env python3
    
    import os
    from hashlib import md5
    from Crypto.Cipher import AES
    from Crypto.Random import get_random_bytes
    from PIL import Image
    from PIL import ImageDraw
    from flag import flag
    
    key = get_random_bytes(8) * 2
    iv = md5(key).digest()
    
    cipher = AES.new(key, AES.MODE_CFB, iv=iv)
    enc = cipher.encrypt(flag)
    
    img = Image.new('RGB', (800, 50))
    drw = ImageDraw.Draw(img)
    drw.text((20, 20), enc.hex(), fill=(255, 0, 0))
    img.save("flag.png")
    
    hkey = ''.join('\\x{:02x}'.format(x) for x in key[:10])
    
    os.system(f'/bin/zip -0 flag.zip flag.png -e -P \"$(/bin/echo -en \"{hkey}\")\"')
    

把flag用AES加密后画到一张图片里，然后用zip压缩，而且是无损压缩，密码就是AES key的前10个字节。

github上有[工具](https://github.com/kimci86/bkcrack)可以Crack legacy zip encryption with Biham and Kocher’s known plaintext attack。这个工具要求我们至少要知道12个明文字节。因为是png文件，所以可以从文件结构下手。

查[wiki](https://zh.wikipedia.org/wiki/PNG)和[png文件标准](http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html)可以知道png有固定的file header，然后第一个data chunk一定是IHDR。

    The IHDR chunk must appear FIRST. It contains:
    
       Width:              4 bytes
       Height:             4 bytes
       Bit depth:          1 byte
       Color type:         1 byte
       Compression method: 1 byte
       Filter method:      1 byte
       Interlace method:   1 byte
    

IHDR中的内容与图片像素内容无关，所以只要生成一个大小和flag.png一样的图片就可以得到33个字节的明文（data chunk有固定的结构，Length, chunk type, CRC加起来有12字节）。

    from PIL import Image
    from PIL import ImageDraw
    
    img = Image.new('RGB', (800, 50))
    img.save("./blobfish/test.png")
    img_data = open("./blobfish/test.png", 'rb').read()
    
    img2 = Image.new('RGB', (800, 50))
    drw = ImageDraw.Draw(img2)
    drw.text((20, 20), "eihei", fill=(255, 0, 0))
    img2.save("./blobfish/test2.png")
    img2_data = open("./blobfish/test2.png", 'rb').read()
    
    print(img_data[:33].hex())
    print(img2_data[:33].hex())
    assert img_data[:33] == img2_data[:33]
    open("./blobfish/plain", 'wb').write(img_data[:33])
    

然后就可以按照[这里](https://github.com/kimci86/bkcrack/blob/master/example/tutorial.md)说的一步一步来。

**What is inside**

    $ ./bkcrack -L flag.zip 
    bkcrack 1.5.0 - 2022-07-07
    Archive: flag.zip
    Index Encryption Compression CRC32    Uncompressed  Packed size Name
    ----- ---------- ----------- -------- ------------ ------------ ----------------
        0 ZipCrypto  Store       2ba69c8a         1168         1180 flag.png
    

**Running the attack**

    $ ./bkcrack -C flag.zip -c flag.png -p plain
    bkcrack 1.5.0 - 2022-07-07
    [18:20:18] Z reduction using 26 bytes of known plaintext
    100.0 % (26 / 26)
    [18:20:18] Attack on 281173 Z values at index 6
    Keys: 03492be6 b81a5123 24d7b146
    29.1 % (81901 / 281173)
    [18:21:02] Keys
    03492be6 b81a5123 24d7b146
    

**Recovering the original files**

    $ ./bkcrack -C flag.zip -c flag.png -k 03492be6 b81a5123 24d7b146 -d flag.png
    bkcrack 1.5.0 - 2022-07-07
    [18:25:23] Writing deciphered data flag.png (maybe compressed)
    Wrote deciphered data.
    

OCR识别出来得到`69f421d9e241933cbc62a9ffe937779c864ffa193de014aeb57046b16c40c7353910c61a2676f14f4c7737f038a6db53262c50`

**Recovering the original password**

    $ ./bkcrack -k 03492be6 b81a5123 24d7b146 -r 10 '?b'
    bkcrack 1.5.0 - 2022-07-07
    [18:37:20] Recovering password
    length 0-6...
    length 7...
    length 8...
    length 9...
    length 10...
    67.8 % (44409 / 65536)
    [18:37:21] Password
    as bytes: ad 6e fb 79 2a ea 5a aa ad 6e 
    as text: �n�y*�Z��n
    

**get flag**

    from Crypto.Cipher import AES
    from Crypto.Random import get_random_bytes
    from hashlib import md5
    
    enc = "69f421d9e241933cbc62a9ffe937779c864ffa193de014aeb57046b16c40c7353910c61a2676f14f4c7737f038a6db53262c50"
    key = 'ad 6e fb 79 2a ea 5a aa'.replace(' ', '')
    key = bytes.fromhex(key*2)
    iv = md5(key).digest()
    
    cipher = AES.new(key, AES.MODE_CFB, iv=iv)
    flag = cipher.decrypt(bytes.fromhex(enc))
    print(flag)
    

### Roldy

    #!/usr/bin/env python3
    
    from Crypto.Util.number import *
    from pyope.ope import OPE as enc
    from pyope.ope import ValueRange
    import sys
    from secret import key, flag
    
    def die(*args):
    	pr(*args)
    	quit()
    
    def pr(*args):
    	s = " ".join(map(str, args))
    	sys.stdout.write(s + "\n")
    	sys.stdout.flush()
    
    def sc(): 
    	return sys.stdin.buffer.readline()
    
    def encrypt(msg, key, params):
    	if len(msg) % 16 != 0:
    		msg += (16 - len(msg) % 16) * b'*'
    	p, k1, k2 = params
    	msg = [msg[_*16:_*16 + 16] for _ in range(len(msg) // 16)]
    	m = [bytes_to_long(_) for _ in msg]
    	inra = ValueRange(0, 2**128)
    	oura = ValueRange(k1 + 1, k2 * p + 1)
    	_enc = enc(key, in_range = inra, out_range = oura)
    	C = [_enc.encrypt(_) for _ in m]
    	return C
    
    def main():
    	border = "|"
    	pr(border*72)
    	pr(border, " Welcome to Roldy combat, we implemented an encryption method to    ", border)
    	pr(border, " protect our secret. Please note that there is a flaw in our method ", border)
    	pr(border, " Can you examine it and get the flag?                               ", border)
    	pr(border*72)
    
    	pr(border, 'Generating parameters, please wait...')
    	p, k1, k2 = [getPrime(129)] + [getPrime(64) for _ in '__']
    	C = encrypt(flag, key, (p, k1, k2))
    
    	while True:
    			pr("| Options: \n|\t[E]ncrypted flag! \n|\t[T]ry encryption \n|\t[Q]uit")
    			ans = sc().decode().lower().strip()
    			if ans == 'e':
    				pr(border, f'encrypt(flag, key, params) = {C}')
    			elif ans == 't':
    				pr(border, 'Please send your message to encrypt: ')
    				msg = sc().rstrip(b'\n')
    				if len(msg) > 64:
    					pr(border, 'Your message is too long! Sorry!!')
    				C = encrypt(msg, key, (p, k1, k2))
    				pr(border, f'C = {C}')
    			elif ans == 'q':
    				die(border, "Quitting ...")
    			else:
    				die(border, "Bye ...")
    
    if __name__ == '__main__':
    	main()
    

使用到一个OPE的加密方法，OPE（保序加密算法）可以保证本来有序的明文加密后依然保持原有的顺序。然后再看这个python库的源码

    class OPE(object):
    
        def __init__(self, key, in_range=None, out_range=None):
            if not isinstance(key, bytes):
                raise TypeError("key: expected bytes, but got %r" % type(key).__name__)
            self.key = key
    
            if in_range is None:
                in_range = ValueRange(DEFAULT_IN_RANGE_START, DEFAULT_IN_RANGE_END)
            self.in_range = in_range
    
            if out_range is None:
                out_range = ValueRange(DEFAULT_OUT_RANGE_START, DEFAULT_OUT_RANGE_END)
            self.out_range = out_range
    
            if in_range.size() > out_range.size():
                raise Exception('Invalid range')
    
        def encrypt(self, plaintext):
            """Encrypt the given plaintext value"""
            if not isinstance(plaintext, int):
                raise ValueError('Plaintext must be an integer value')
            if not self.in_range.contains(plaintext):
                raise OutOfRangeError('Plaintext is not within the input range')
            return self.encrypt_recursive(plaintext, self.in_range, self.out_range)
    
        def encrypt_recursive(self, plaintext, in_range, out_range):
            in_size = in_range.size()       # M
            out_size = out_range.size()     # N
            in_edge = in_range.start - 1    # d
            out_edge = out_range.start - 1  # r
            mid = out_edge + int(math.ceil(out_size / 2.0))  # y
            assert in_size <= out_size
            if in_range.size() == 1:
                coins = self.tape_gen(plaintext)
                ciphertext = stat.sample_uniform(out_range, coins)
                return ciphertext
            coins = self.tape_gen(mid)
            x = stat.sample_hgd(in_range, out_range, mid, coins)
    
            if plaintext <= x:
                in_range = ValueRange(in_edge + 1, x)
                out_range = ValueRange(out_edge + 1, mid)
            else:
                in_range = ValueRange(x + 1, in_edge + in_size)
                out_range = ValueRange(mid + 1, out_edge + out_size)
            return self.encrypt_recursive(plaintext, in_range, out_range)
    

简单地说就是把在`in_range`的明文映射到`out_range`，中间怎么映射的可以不用管。然后再看如何decrypt

        def decrypt_recursive(self, ciphertext, in_range, out_range):
            in_size = in_range.size()       # M
            out_size = out_range.size()     # N
            in_edge = in_range.start - 1    # d
            out_edge = out_range.start - 1  # r
            mid = out_edge + int(math.ceil(out_size / 2.0))  # y
            assert in_size <= out_size
            if in_range.size() == 1:
                in_range_min = in_range.start
                coins = self.tape_gen(in_range_min)
                sampled_ciphertext = stat.sample_uniform(out_range, coins)
                if sampled_ciphertext == ciphertext:
                    return in_range_min
                else:
                    raise InvalidCiphertextError('Invalid ciphertext')
            coins = self.tape_gen(mid)
            x = stat.sample_hgd(in_range, out_range, mid, coins)
    
            if ciphertext <= mid:
                in_range = ValueRange(in_edge + 1, x)
                out_range = ValueRange(out_edge + 1, mid)
            else:
                in_range = ValueRange(x + 1, in_edge + in_size)
                out_range = ValueRange(mid + 1, out_edge + out_size)
            return self.decrypt_recursive(ciphertext, in_range, out_range)
    

用到一个binary search，那么在这题也可以用binary search来解决，只是不知道中间的映射过程，搜索的范围大了一点。

    from pwn import *
    from Crypto.Util.number import long_to_bytes
    sh = remote("06.cr.yp.toc.tf", 31377)
    
    inra_min = 0
    inra_max = 2**128
    
    known_flag = b"CCTF{Boldyreva_5ymMe7rIC_0rD3r_pRe5Erv!n9_3nCryp7i0n!_LStfig9TM}"
    
    def get_enc_flag():
        sh.sendlineafter(b"Options:", b'E')
        sh.recvuntil(b"encrypt(flag, key, params) = ")
        enc_s = sh.recvline()[:-1].decode()
        return eval(enc_s)
    
    def send_and_recv(msg: int):
        sh.sendlineafter(b"Options:", b'T')
        sh.sendlineafter(b"Please send your message to encrypt:", known_flag+long_to_bytes(msg, 16))
        sh.recvuntil(b"C = ")
        enc_s = sh.recvline()[:-1].decode()
        return eval(enc_s)
    
    def compare_block(o, t, indix):
        if o[indix] < t[indix]:
            return -1
        elif o[indix] == t[indix]:
            print(f"[+]     find a block {o[indix]}")
            return 0
        else:
            return 1
    
    enc_flag = get_enc_flag()
    print(enc_flag)
    
    boundary = [
        (89407868913636251168773770536032493343, 89407868913636251168773770536032493377),
        (161404117612298851011345476078246453087, 161404117612298851011345476078246453121),
        (109522198106951428429083248646293684223, 109522198106951428429083248646293749761),
        (73653713219403595476250315686415715707, 73653713219403595476250315686415715714)
        ]
    
    cnt = 1
    block_id = 3
    min, max = boundary[block_id]
    try:
        while min < max:
            mid = (max + min) // 2
            temp = send_and_recv(mid)
            res = compare_block(temp, enc_flag, block_id)
            if res == 0:
                print(long_to_bytes(mid))
                break
            elif res == -1:
                min = mid-1
                print(f"{cnt}: smaller than flag, try more bigger")
            else:
                max = mid+1
                print(f"{cnt}: bigger than flag, try more smaller")
            cnt += 1
    except:
        print(f"{min = }, {max = }")
    

### keymoted

    #!/usr/bin/env sage
    
    from Crypto.Util.number import *
    from flag import flag
    
    def gen_koymoted(nbit):
    	p = getPrime(nbit)
    	a, b = [randint(1, p - 1) for _ in '__']
    	Ep = EllipticCurve(GF(p), [a, b])
    	tp = p + 1 - Ep.order()
    	_s = p ^^ ((2 ** (nbit - 1)) + 2 ** (nbit // 2))
    	q = next_prime(2 * _s + 1)
    	Eq = EllipticCurve(GF(q), [a, b])
    	n = p * q
    	tq = q + 1 - Eq.order()
    	e = 65537
    	while True:
    		if gcd(e, (p**2 - tp**2) * (q**2 - tq**2)) == 1:
    			break
    		else:
    			e = next_prime(e)
    	pkey, skey = (n, e, a, b), (p, q)
    	return pkey, skey
    
    def encrypt(msg, pkey, skey):
    	n, e, a, b = pkey
    	p, q = skey
    	m = bytes_to_long(msg)
    	assert m < n
    	while True:
    		xp = (m**3 + a*m + b) % p
    		xq = (m**3 + a*m + b) % q
    		if pow(xp, (p-1)//2, p) == pow(xq, (q-1)//2, q) == 1:
    			break
    		else:
    			m += 1
    	eq1, eq2 = Mod(xp, p), Mod(xq, q)
    	rp, rq = sqrt(eq1), sqrt(eq2)
    	_, x, y = xgcd(p, q)
    	Z = Zmod(n)
    	x = (Z(rp) * Z(q) * Z(y) + Z(rq) * Z(p) * Z(x)) % n
    	E = EllipticCurve(Z, [a, b])
    	P = E(m, x)
    	enc = e * P
    	return enc
    
    nbit = 256
    pkey, skey = gen_koymoted(nbit)
    enc = encrypt(flag, pkey, skey)
    
    print(f'pkey = {pkey}')
    print(f'enc = {enc}')
    

一个非常常规的RSA+EC，我之前的一篇[文章](https://clingm.github.io/2022/10/02/A-New-Elliptic-Curve-Based-Analogue-of-RSA/)就分析过，所以重点还是放在分解n。 $$ n=p_q\\ q = 2_(p-2^{256} + 2^{128})+1+t\\ or\\ 2\*(p-2^{256} - 2^{128})+1+t $$ 由于t很小可以忽略，所以可以构造出两个关于p的二次方程，然后可以得到两个p的近似，最后用coppersmith解p的低位就可以，其中一个近似的结果是解不出来的。

    from Crypto.Util.number import getPrime, GCD
    from gmpy2 import iroot
    from sage.all import PolynomialRing, Zmod
    pkey = (6660938713055850877314255610895820875305739186102790477966786501810416821294442374977193379731704125177528590285016474818841859956990486067573436301232301, 65537, 5539256645640498184116966196249666621079506508209770360679460869295427007578, 20151017657582479433586370393795140515103572865771721775868586710594524816458)
    enc = (6641320679869421443758875467781930795132746694454926965779628505713445486895274490835545942727970688359873955019634877304270220728625521646208912044469433 , 2856872654927815636828860866843721158889474116106462420201092148493803550131351543372740950198853438539317164093538508795630146854596724019329887894933972 , 1)
    n, e, a, b = pkey
    nbit = 256
    r = 2 ** (nbit - 1)
    s = 2 ** (nbit // 2)
    
    # a, b, c = 2, -2*(r+s), -n
    # delta = b**2 - 4*a*c
    # p_ = (-b + iroot(delta, 2)[0]) // (2*a)
    # print(p_, p_.bit_length())
    """
    93511613846272978051774379195449772332692693333173612296021789501865098047642
    93511613846272978051774379195449772333185546232721473548443129310958604273824
    """
    p_ = 93511613846272978051774379195449772332692693333173612296021789501865098047642
    R = PolynomialRing(Zmod(n), 'x')
    x = R.gen()
    f = p_ + x
    root = f.small_roots(X=2**50, beta=0.42)
    p = GCD(n, f(x=root[0]))
    q = n // p
    assert p*q == n
    print(p, q)
    

然后就是很常规的decrypt

    from Crypto.Util.number import long_to_bytes
    from sympy import legendre_symbol
    from sage.all import EllipticCurve, GF, inverse_mod, Zmod
    from math import lcm
    
    pkey = (6660938713055850877314255610895820875305739186102790477966786501810416821294442374977193379731704125177528590285016474818841859956990486067573436301232301, 65537, 5539256645640498184116966196249666621079506508209770360679460869295427007578, 20151017657582479433586370393795140515103572865771721775868586710594524816458)
    enc = (6641320679869421443758875467781930795132746694454926965779628505713445486895274490835545942727970688359873955019634877304270220728625521646208912044469433 , 2856872654927815636828860866843721158889474116106462420201092148493803550131351543372740950198853438539317164093538508795630146854596724019329887894933972 , 1)
    n, e, a, b = pkey
    
    p, q = 93511613846272978051774379195449772332692693333173612296021789501865098047641, 71231138455229760679977773382211636812795966734548537479512744210680602878261
    
    orderp = EllipticCurve(GF(p), [a, b]).order()
    orderq = EllipticCurve(GF(q), [a, b]).order()
    tp = p + 1 - orderp
    tq = q + 1 - orderq
    cx = enc[0]
    u = (cx**3 + a*cx + b) % n
    up = legendre_symbol(u, p)
    uq = legendre_symbol(u, q)
    assert up == uq == 1
    d = inverse_mod(e, lcm(p+1-tp, q+1-tq))
    E = EllipticCurve(Zmod(n), [a, b])
    c = E((enc[0], enc[1]))
    m = d*c
    
    print(long_to_bytes(int(m[0])))
    

最后得到的flag的最后一位要修正一下，因为前面生成点的时候要求满足二次剩余。

DASCTF X 0x401
==============

ezDHKE
------

    from Crypto.Util.number import *
    from Crypto.Cipher import AES
    from hashlib import sha256
    from random import randbytes, getrandbits
    from flag import flag
    
    def diffie_hellman(g, p, flag):
        alice = getrandbits(1024)
        bob = getrandbits(1024)
        alice_c = pow(g, alice, p)
        bob_c = pow(g, bob, p)
        print(alice_c , bob_c)
        key = sha256(long_to_bytes(pow(bob_c, alice, p))).digest()
        iv = b"dasctfdasctfdasc"
        aes = AES.new(key, AES.MODE_CBC, iv)
        enc = aes.encrypt(flag)
        print(enc)
    
    def getp():
        p = int(input("P = "))
        assert isPrime(p)
        assert p.bit_length() >= 1024 and p.bit_length() <= 2048
        g = 2
        diffie_hellman(g, p, flag)
    
    getp()
    

由我们提供modulu p，然后做DHKE，直接给一个p-1 smooth的prime，然后用pohlig-hellman解dlp。

    from Crypto.Util.number import getPrime, isPrime, long_to_bytes, sieve_base
    from Crypto.Cipher import AES
    from hashlib import sha256
    from pwn import *
    import random
    from sage.all import discrete_log, GF
    
    context.log_level = 'debug'
    is_remote=True
    if is_remote:
        sh = remote("node4.buuoj.cn", 25735)
    else:
        sh = process(["python", "problem_2.py"])
    
    def getSmoothP(lbound, ubound,digits):
        flag = False
        while not flag:
            pSmooth = 2
            primes = []
            while (pSmooth.bit_length() < lbound or not isPrime(pSmooth+1)):
                prime = getPrime(random.randint(2, digits))
                if prime not in primes:
                    pSmooth *= prime
                    primes.append(prime)
            flag = True
            if pSmooth.bit_length() > ubound:
                flag = False
        pSmooth += 1
        return pSmooth, primes
    
    # p, facs = getSmoothP(1024, 2048, 16)
    # print(p, isPrime(p), p.bit_length())
    # print(facs)
    p = 4105711157686384919659886084922308099345091031616266488383302451817555397122028096174284199260242246031324358818375139627204894374290872468958930235949674619183046042244975516625978894843032524347866836336310274102966648274039354672718733827938995471650785973542486210912102927279955176856005649816015734404405654263337144365315329431
    fac = [3, 47951, 859, 7, 127, 1213, 71, 131, 1009, 389, 1439, 7043, 50627, 27479, 7027, 673, 3271, 467, 5, 1867, 6389, 31721, 19, 25763, 19973, 73, 359, 5237, 839, 449, 26119, 47, 223, 773, 821, 83, 881, 827, 40433, 22273, 21997, 21893, 31, 977, 463, 2357, 383, 1289, 7577, 3251, 491, 4129, 2693, 43, 919, 23, 181, 36187, 347, 661, 149, 23447, 11, 4673, 101, 43313, 24391, 1693, 97, 151, 1063, 10039, 1993, 179, 13, 17, 7927, 61, 52259, 18367, 229, 1301, 5483, 3067, 79, 157, 41, 62903, 10889, 113, 33937, 29153, 34871, 6337, 13591, 59, 199, 6089, 15467, 6563, 48193, 1597, 163, 2683, 137, 3301, 29921, 8831]
    
    sh.sendlineafter(b"P = ", str(p).encode())
    alice_c = int(sh.recvuntil(b' '))
    bob_c = int(sh.recvline().decode()[:-1])
    print(f"{alice_c = }\n{bob_c = }")
    enc = eval(sh.recvline()[:-1])
    print(enc, len(enc))
    g = GF(p)(2)
    alice = int(discrete_log(alice_c, g, ord=p-1))
    bob = int(discrete_log(bob_c, g, ord=p-1))
    print(f"{alice = }\n{bob = }")
    print(f"{pow(alice_c, bob, p) == pow(bob_c, alice, p)}")
    key = sha256(long_to_bytes(pow(bob_c, alice, p))).digest()
    iv = b"dasctfdasctfdasc"
    aes = AES.new(key, AES.MODE_CBC, iv)
    flag = aes.decrypt(enc)
    print(flag)
    sh.close()
    

ezRSA
-----

    from Crypto.Util.number import *
    from secret import secret, flag
    def encrypt(m):
        return pow(m, e, n)
    assert flag == b"dasctf{" + secret + b"}"
    e = 11
    p = getPrime(512)
    q = getPrime(512)
    n = p * q
    P = getPrime(512)
    Q = getPrime(512)
    N = P * Q
    gift = P ^ (Q >> 16)
    print(N, gift, pow(n, e, N))
    print(encrypt(bytes_to_long(secret)),
        encrypt(bytes_to_long(flag)))
    
    # 75000029602085996700582008490482326525611947919932949726582734167668021800854674616074297109962078048435714672088452939300776268788888016125632084529419230038436738761550906906671010312930801751000022200360857089338231002088730471277277319253053479367509575754258003761447489654232217266317081318035524086377 8006730615575401350470175601463518481685396114003290299131469001242636369747855817476589805833427855228149768949773065563676033514362512835553274555294034 14183763184495367653522884147951054630177015952745593358354098952173965560488104213517563098676028516541915855754066719475487503348914181674929072472238449853082118064823835322313680705889432313419976738694317594843046001448855575986413338142129464525633835911168202553914150009081557835620953018542067857943
    # 69307306970629523181683439240748426263979206546157895088924929426911355406769672385984829784804673821643976780928024209092360092670457978154309402591145689825571209515868435608753923870043647892816574684663993415796465074027369407799009929334083395577490711236614662941070610575313972839165233651342137645009 46997465834324781573963709865566777091686340553483507705539161842460528999282057880362259416654012854237739527277448599755805614622531827257136959664035098209206110290879482726083191005164961200125296999449598766201435057091624225218351537278712880859703730566080874333989361396420522357001928540408351500991
    

要先根据gift分解N，gift的高16 bits就是p的高16 bits，所以可以求得q\[:16\] = N // p\[0:16\]，然后q\[0:16\] xor gitf\[16:32\]得到p\[16:32\]，循环直到恢复p。但是这样会有误差，所以取小一点比如10 bits或8 bits，最好是$2^n$，比如2， 4， 8，这样可以直接得到完整的p。

然后就是熟悉的related message attack。

    from Crypto.Util.number import getPrime, inverse, long_to_bytes
    from sage.all import PolynomialRing, Zmod
    from ctf.attacks.rsa.related_message import attack
    
    N, gift, h = 75000029602085996700582008490482326525611947919932949726582734167668021800854674616074297109962078048435714672088452939300776268788888016125632084529419230038436738761550906906671010312930801751000022200360857089338231002088730471277277319253053479367509575754258003761447489654232217266317081318035524086377 ,8006730615575401350470175601463518481685396114003290299131469001242636369747855817476589805833427855228149768949773065563676033514362512835553274555294034 ,14183763184495367653522884147951054630177015952745593358354098952173965560488104213517563098676028516541915855754066719475487503348914181674929072472238449853082118064823835322313680705889432313419976738694317594843046001448855575986413338142129464525633835911168202553914150009081557835620953018542067857943
    enc_s, enc_flag = 69307306970629523181683439240748426263979206546157895088924929426911355406769672385984829784804673821643976780928024209092360092670457978154309402591145689825571209515868435608753923870043647892816574684663993415796465074027369407799009929334083395577490711236614662941070610575313972839165233651342137645009, 46997465834324781573963709865566777091686340553483507705539161842460528999282057880362259416654012854237739527277448599755805614622531827257136959664035098209206110290879482726083191005164961200125296999449598766201435057091624225218351537278712880859703730566080874333989361396420522357001928540408351500991
    
    
    p_highbit = bin(gift)[2:][:16]
    gift = bin(gift)[2:][16:]
    
    kbits = 8
    for i in range((512 - 16)//kbits):
        p_ = int(p_highbit.ljust(512, '0'), 2)
        q_ = N // p_
        q_highbit = bin(q_)[2:]
        s = min(i*kbits, 512)
        d = min(s+kbits, 512)
        r = bin(int(q_highbit[s:d], 2) ^ int(gift[s:d], 2))[2:].zfill(kbits)
    
        p_highbit += r
    
    p_high = int(p_highbit, 2)
    p = p_high
    q = N // p
    assert p*q == N
    
    phi1 = (p-1)*(q-1)
    e = 11
    d1 = inverse(e, phi1)
    n = pow(h, d1, N) + N
    print(n)
    
    f1=lambda x: x
    for l in range(100):
        f2 = lambda x: x*2**8 + int.from_bytes(b"dasctf{" + b"\x00"*l + b"}", 'big')
        m = attack(n, e, enc_s, enc_flag, f1, f2)
        if m != n-1:
            print(m)
            print(long_to_bytes(m))
            break
    

ezAlgebra
---------

    from Crypto.Util.number import getPrime, bytes_to_long
    
    def YiJiuJiuQiNian(Wo, Xue, Hui, Le, Kai):
        Qi = 1997
        Che = Wo+Hui if Le==1 else Wo*Hui
        while(Xue):
            Qi += (pow(Che, Xue, Kai)) % Kai
            Xue -= 1
        return Qi
        
    l = 512
    m = bytes_to_long(flag)
    p = getPrime(l)
    q = getPrime(l//2)
    r = getPrime(l//2)
    n = p * q * r
    t = getrandbits(32)
    c1 = YiJiuJiuQiNian(t, 4, p, 1, n)
    c2 = YiJiuJiuQiNian(m, 19, t, 0, q)
    c3 = YiJiuJiuQiNian(m, 19, t, 1, q)
    print(f"n = {n}")
    print(f"c1 = {c1}")
    print(f"c2 = {c2}")
    print(f"c3 = {c3}")
    

首先对于c1，看到$(x+p)^n$很自然的把二项式展开mod p。 $$ c1-1997\\equiv \\sum\_{i=1}^{4}{t^i}\\pmod{p} $$ 由于t是很小的解，直接用small roots可以得到，然后就可以gcd算p。

然后有两个多项式 $$ \\sum\_{i=1}^{19}{(x+t)^i} + 1997 - c2 \\equiv 1\\pmod{q}\\ \\sum\_{i=1}^{19}{(xt)^i} + 1997 - c2 \\equiv 1\\pmod{q} $$ 不知道的量是q和x，两个变量两个方程可以用groebner basis解。

最后解出来的x并不是real flag，还要用$kq$爆破(k还挺大的)。

    from Crypto.Util.number import isPrime, long_to_bytes
    from sage.all import Zmod, ZZ, Ideal
    from math import gcd
    
    l=512
    n = 119156144845956004769507478085325079414190248780654060840257869477965140304727088685316579445017214576182010373548273474121727778923582544853293534996805340795355149795694121455249972628980952137874014208209750135683003125079012121116063371902985706907482988687895813788980275896804461285403779036508897592103
    c1 = 185012145382155564763088060801282407144264652101028110644849089283749320447842262397065972319766119386744305208284231153853897076876529326779092899879401876069911627013491974285327376378421323298147156687497709488102574369005495618201253946225697404932436143348932178069698091761601958275626264379615139864425
    c2 = 722022978284031841958768129010024257235769706227005483829360633993196299360813
    c3 = 999691052172645326792013409327337026208773437618455136594949462410165608463231
    
    x = Zmod(n)['x'].gen()
    f = x**4 + x**3 + x**2 + x - c1 + 1997
    t = f.small_roots(X=2**32, beta=0.4)[0]
    
    p = gcd(n, f.change_ring(ZZ)(x=t))
    assert isPrime(p)
    print(f"{p = }")
    
    x, y = Zmod(n)['x, y'].gens()
    f1 = 1997 - c2
    f2 = 1997 - c3
    for i in range(1, 20):
        f1 += (y*t)**i
        f2 += (y+t)**i
    
    I = Ideal(f1, f2)
    print(I.groebner_basis())
    
    def poly_gcd(a, b):
        while b:
            a, b = b, a % b
        return a.monic()
    
    y = -21158731716376226090392498841915660119151249151578293634082749989659307225047065454562556490794720241251831294269248252992828782428316834166828404876181491874871787144664849984606114249820338190252050491223066273953777506705536480844475141933848618113343415375867066617512805575869013694523034573111259114274
    q = 87038069032840052005520908272237788908169043580221040711149494083975743478969
    m = y % q
    for i in range(999999, 10000000):
        flag = long_to_bytes(m + i*q)
        if b'dasctf' in flag:
            print(flag)
    

巅峰极客 2023
=========

数学但高中
-----

    x=4{0<y<6}
    
    y=4{2<x<6,17<x<18,28<x<30,41<x<42}
    
    y=6{4<x<6,15<x<16,17<x<19,41<x<43,50<x<51}
    
    x=7{0<y<6}
    
    (x-9)^2+(y-3)^2=1
    
    x=10{2<y<3}
    
    (x-12)^2+(y-3)^2=1
    
    x=13{0<y<3}
    
    y=0{11<x<13,15<x<16,50<x<51}
    
    y=-x+17{14<x<15}
    
    y=x-11{14<x<15}
    
    x=15{0<y<2,4<y<6}
    
    x=17{1<y<6}
    
    x=19{3<y<4}
    
    x=21{3<y<4}
    
    (x-20)^2+(y-3)^2=1{2<y<3}
    
    (x-23)^2+(y-3)^2=1{3<y<4}
    
    x=22{2<y<3}
    
    x=24{2<y<3}
    
    (x-26)^2+(y-3)^2=1{25<x<26}
    
    y=0.5x-11{26<x<27}
    
    y=-0.5x+17{26<x<27}
    
    y=2{29<x<30,31<x<33,39<x<40}
    
    x=29{2<y<5}
    
    x=32{2<y<5}
    
    y=x-27{31<x<32}
    
    (x-34)^2+((y-3.5)^2)/(1.5^2)=1
    
    x=36{2<y<3}
    
    (x-37)^2+(y-3)^2=1{3<y<4}
    
    x=38{2<y<3}
    
    x=41{2<y<6}
    
    x=44{3<y<4}
    
    (x-45)^2+(y-3)^2=1{2<y<3}
    
    x=46{3<y<4}
    
    x=47{2<y<3}
    
    (x-48)^2+(y-3)^2=1{3<y<4}
    
    x=49{2<y<3}
    
    x=51{0<y<2,4<y<6}
    
    y=x-49{51<x<52}
    
    y=-x+55{51<x<52}
    

根据上面这些把flag画出来

![image-20230724155702070](https://cdn.jsdelivr.net/gh/clingm/PicGo-image//img/image-20230724155702070.png)

中间有个o是个椭圆我嫌麻烦就没画。

Flag: `flag{Funct1on_Fun}`

Simple\_encryption
------------------

    from Crypto.Util.number import *
    import gmpy2
    import random
    import binascii
    from secret import flag
    
    p = getStrongPrime(1024)
    q = getStrongPrime(1024)
    N = p * q
    g, r1, r2 = [getRandomRange(1, N) for _ in range(3)]
    g1 = pow(g, r1 * (p - 1), N)
    g2 = pow(g, r2 * (q - 1), N)
    
    
    def encrypt(m):
        s1, s2 = [getRandomRange(1, N) for _ in range(2)]
        c1 = (m * pow(g1, s1, N)) % N
        c2 = (m * pow(g2, s2, N)) % N
        print("c1=", c1)
        print("c2=", c2)
        return (c1, c2)
    
    
    c = encrypt(bytes_to_long(flag[:len(flag) // 2]))
    print('N=', N)
    print('g1=', g1)
    
    
    def pad(msg, length):
        l = len(msg)
        return msg + (length - l) * chr(length - l).encode('utf-8')
    
    
    p = getStrongPrime(1024)
    q = getStrongPrime(1024)
    assert (p != q)
    n = p * q
    e = 5
    d = inverse(e, (p - 1) * (q - 1))
    assert (e * d % (p - 1) * (q - 1))
    
    flag = pad(flag[len(flag) // 2:], 48)
    m = [int(binascii.b2a_hex(flag[i * 16:i * 16 + 16]).decode('utf-8'), 16) for i in range(3)]
    print('S=', sum(m) % n)
    cnt = len(m)
    A = [(i + 128) ** 2 for i in range(cnt)]
    B = [(i + 1024) for i in range(cnt)]
    C = [(i + 512) for i in range(cnt)]
    Cs = [int(pow((A[i] * m[i] ** 2 + B[i] * m[i] + C[i]), e, n)) for i in range(cnt)]
    print('N=', n)
    print('e=', e)
    print('Cs=', Cs)
    
    '''
    c1= 19024563955839349902897822692180949371550067644378624199902067434708278125346234824900117853598997270022872667319428613147809325929092749312310446754419305096891122211944442338664613779595641268298482084259741784281927857614814220279055840825157115551456554287395502655358453270843601870807174309121367449335110327991187235786798374254470758957844690258594070043388827157981964323699747450405814713722613265012947852856714100237325256114904705539465145676960232769502207049858752573601516773952294218843901330100257234517481221811887136295727396712894842769582824157206825592614684804626241036297918244781918275524254
    c2= 11387447548457075057390997630590504043679006922775566653728699416828036980076318372839900947303061300878930517069527835771992393657157069014534366482903388936689298175411163666849237525549902527846826224853407226289495201341719277080550962118551001246017511651688883675152554449310329664415179464488725227120033786305900106544217117526923607211746947511746335071162308591288281572603417532523345271340113176743703809868369623401559713179927002634217140206608963086656140258643119596968929437114459557916757824682496866029297120246221557017875892921591955181714167913310050483382235498906247018171409256534124073270350
    N= 21831630625212912450058787218272832615084640356500740162478776482071876178684642739065105728423872548532056206845637492058465613779973193354996353323494373418215019445325632104575415991984764454753263189235376127871742444636236132111097548997063091478794422370043984009615893441148901566420508196170556189546911391716595983110030778046242014896752388438535131806524968952947016059907135882390507706966746973544598457963945671064540465259211834751973065197550500334726779434679470160463944292619173904064826217284899341554269864669620477774678605962276256707036721407638013951236957603286867871199275024050690034901963
    g1= 20303501619435729000675510820217420636246553663472832286487504757515586157679361170332171306491820918722752848685645096611030558245362578422584797889428493611704976472409942840368080016946977234874471779189922713887914075985648876516896823599078349725871578446532134614410886658001724864915073768678394238725788245439086601955497248593286832679485832319756671985505398841701463782272300202981842733576006152153012355980197830911700112001441621619417349747262257225469106511527467526286661082010163334100555372381681421874165851063816598907314117035131618062582953512203870615406642787786668571083042463072230605649134
    S= 234626762558445335519229319778735528295
    N= 28053749721930780797243137464055357921262616541619976645795810707701031602793034889886420385567169222962145128498131170577184276590698976531070900776293344109534005057067680663813430093397821366071365221453788763262381958185404224319153945950416725302184077952893435265051402645871699132910860011753502307815457636525137171681463817731190311682277171396235160056504317959832747279317829283601814707551094074778796108136141845755357784361312469124392408642823375413433759572121658646203123677327551421440655322226192031542368496829102050186550793124020718643243789525477209493783347317576783265671566724068427349961101
    e= 5
    Cs= [1693447496400753735762426750097282582203894511485112615865753001679557182840033040705025720548835476996498244081423052953952745813186793687790496086492136043098444304128963237489862776988389256298142843070384268907160020751319313970887199939345096232529143204442168808703063568295924663998456534264361495136412078324133263733409362366768460625508816378362979251599475109499727808021609000751360638976, 2240772849203381534975484679127982642973364801722576637731411892969654368457130801503103210570803728830063876118483596474389109772469014349453490395147031665061733965097301661933389406031214242680246638201663845183194937353509302694926811282026475913703306789097162693368337210584494881249909346643289510493724709324540062077619696056842225526183938442535866325407085768724148771697260859350213678910949, 5082341111246153817896279104775187112534431783418388292800705085458704665057344175657566751627976149342406406594179073777431676597641200321859622633948317181914562670909686170531929552301852027606377778515019377168677204310642500744387041601260593120417053741977533047412729373182842984761689443959266049421034949822673159561609487404082536872314636928727833394518122974630386280495027169465342976]
    '''
    

**第一部分** $$ g\_1=g^{r\_1\*(p-1)} \\pmod{N}\\ g\_2=g^{r\_2\*P(q-1)}\\pmod{N}\\

g\_1=g^{r\_1\*(p-1)}=1\\pmod{p}\\ g\_1-1=kp\\ p = \\gcd(n, g\_1-1)\\ c\_1=m\*g\_1^{s1}\\pmod{N}\\ m=c\_1\\ mod\\ p $$ **第二部分**

e很小直接开根，然后解二次方程：

    from Crypto.Util.number import *
    from gmpy2 import iroot
    from sage.all import sqrt
    
    S= 234626762558445335519229319778735528295
    N= 28053749721930780797243137464055357921262616541619976645795810707701031602793034889886420385567169222962145128498131170577184276590698976531070900776293344109534005057067680663813430093397821366071365221453788763262381958185404224319153945950416725302184077952893435265051402645871699132910860011753502307815457636525137171681463817731190311682277171396235160056504317959832747279317829283601814707551094074778796108136141845755357784361312469124392408642823375413433759572121658646203123677327551421440655322226192031542368496829102050186550793124020718643243789525477209493783347317576783265671566724068427349961101
    e= 5
    Cs= [1693447496400753735762426750097282582203894511485112615865753001679557182840033040705025720548835476996498244081423052953952745813186793687790496086492136043098444304128963237489862776988389256298142843070384268907160020751319313970887199939345096232529143204442168808703063568295924663998456534264361495136412078324133263733409362366768460625508816378362979251599475109499727808021609000751360638976, 2240772849203381534975484679127982642973364801722576637731411892969654368457130801503103210570803728830063876118483596474389109772469014349453490395147031665061733965097301661933389406031214242680246638201663845183194937353509302694926811282026475913703306789097162693368337210584494881249909346643289510493724709324540062077619696056842225526183938442535866325407085768724148771697260859350213678910949, 5082341111246153817896279104775187112534431783418388292800705085458704665057344175657566751627976149342406406594179073777431676597641200321859622633948317181914562670909686170531929552301852027606377778515019377168677204310642500744387041601260593120417053741977533047412729373182842984761689443959266049421034949822673159561609487404082536872314636928727833394518122974630386280495027169465342976]
    
    Cs_ = [int(iroot(Cs_i, e)[0]) for Cs_i in Cs]
    cnt = 3
    A = [(i + 128) ** 2 for i in range(cnt)]
    B = [(i + 1024) for i in range(cnt)]
    C = [(i + 512) for i in range(cnt)]
    
    def sol(a, b, c):
        delta = b**2 - 4*a*c
        assert delta > 0
        return (-b + int(sqrt(delta))) // (2*a)
    
    for i in range(cnt):
        print(long_to_bytes(sol(A[i], B[i], C[i]-Cs_[i])))
    

Rosita
------

非常好的一道题目，参考[无趣的浅的wp](https://blog.csdn.net/qq_41626232/article/details/131861414)。

### Recover Elliptic Curve

题目给了很多个曲线上的点，找关系式去求解a, b, p

先假设3个点 $$ (x\_1,y\_1):y\_1^2=x\_1^3+ax\_1+b\\ \\ mod\\ p\\\\ (x\_2,y\_2):y\_2^2=x\_2^3+ax\_2+b\\ \\ mod\\ p\\\\ (x\_3,y\_3):y\_3^2=x\_3^3+ax\_3+b\\ \\ mod\\ p $$ 找关系 $$ T\_1=(y\_1^2-x\_1^3)-(y\_2^2-x\_2^3)=a(x\_1-x\_2)\\\\ T\_2=(y\_1^2-x\_1^3)-(y\_3^2-x\_3^3)=a(x\_1-x\_3)\\\\ T\_1(x\_1-x\_3)-T\_2(x\_1-x\_2)=0\\pmod{p} $$ 多求出几组求gcd就可以得到p，解方程得到a, b。

### Analizy Curve

求出椭圆曲线的第一件事就是分析order。发现$#E\_p=p$，满足Smart attack的条件，所以可以求$Q\_i=d\_iG$ $$ \\vec{Q}=\\vec{d}G $$

### ortho lattice attack

> 正交格攻击我后面还想再写一篇blog来仔细研究一下

$$ \\vec{Q}=M\\cdot (R,E,C)\\ $$

$$ M=\\begin{bmatrix} m\_0 & nonce\_0 & sh\_0\\ m\_1 & nonce\_1 & sh\_1\\ \\vdots & \\ddots \\ m\_{73} & nonce\_{73} & sh\_{73}\\ \\end{bmatrix} $$

进而 $$ M\\cdot (R,E,C)^T=\\vec{d}\\cdot G $$ 假设有一个格$A$与$\\vec{d}$正交 $$ A\\vec{d}=0\\pmod{p} $$ 那么 $$ AM=0 $$ 而M就是A的right kernel，

所以构造 $$ L=\\begin{bmatrix} \\vec{d} & I \\ q & 0 \\end{bmatrix} $$

$$ (A|k)\\cdot L=\\begin{bmatrix} 0 & A \\end{bmatrix} $$

所以LLL可以求出A，然后对A的right kernel 规约，出来的第一行就是flag

    from sage.all import *
    from functools import reduce
    from ctf.attacks.ecc.smart_attack import attack
    from tqdm import tqdm
    from Crypto.Util.number import long_to_bytes
    points = eval(open("out.tuo", 'r').read())
    kp = []
    
    for i1, i2, i3 in [points[3*i:3*(i+1)] for i in range(len(points)//3)]:
        x1, y1 = i1
        x2, y2 = i2
        x3, y3 = i3
        kp.append( ((y1**2 - x1**3) - (y2**2 - x2**3))*(x1-x3) - ((y1**2 - x1**3) - (y3**2 - x3**3))*(x1-x2) )
    
    p = reduce(gcd, kp)
    
    a = ((y1**2 - y2**2) - (x1**3 - x2**3)) * inverse_mod(x1-x2, p) % p
    b = (y1**2 - x1**3 - a*x1) % p
    
    print(a, b)
    
    E = EllipticCurve(GF(p), [a, b])
    G = E.gens()[0]
    
    # d = []
    # for i in tqdm(points):
    #     di = attack(G, E(i))
    #     d.append(di)
    # assert len(d) == len(points)
    
    # open("d.txt", 'w').write(str(d))
    d = eval(open("d.txt", 'r').read())
    
    L = matrix(ZZ, len(d)+1)
    for i in range(len(d)):
        L[i, 0] = d[i]
        L[i, i+1] = 1
    L[-1, 0] = p
    L = L.LLL()
    ret = []
    for row in L:
        if row[0] == 0:
            ret.append(row[1:])
    print(len(ret))
    
    M = matrix(ZZ, ret)
    print(f"M : {M.nrows()} X {M.ncols()}")
    m = block_matrix(ZZ, [
        [M[:, :70], identity_matrix(70)]
    ]).LLL()
    print(m[:, 0].T)
    key = matrix(ZZ, M.right_kernel().basis()).LLL()[0]
    print(len(key))
    print("flag:")
    for i in key:
        print(chr(long_to_bytes(ZZ(i))[8]), end='')
    print()
    

Flag: `Congratulations! Your flag is: flag{893d041e-c0a2-3145-5320-cdee7d3c87fb}`
