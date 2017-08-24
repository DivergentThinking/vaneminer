#!/usr/bin/env python3
from hashlib import sha256
from itertools import takewhile
import sys

dsha = lambda d: sha256(sha256(d).digest()).digest()

b58c = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(d):
    n = int.from_bytes(d, "big")
    lz = len(list(takewhile(lambda x: not x, d)))
    o = ""
    while n:
        n, d = divmod(n, 58)
        o += b58c[d]
    return ("1" * lz) + o[::-1]

def b58dec(s):
    o = 0
    for c in s:
        o *= 58
        o += b58c.index(c)
    return o.to_bytes(int(round(o.bit_length()/8+0.5)), "big")

with open(sys.argv[1], "rb") as f:
    d = f.read()

CHUNKSIZE=21
datalen = len(d)
nchunks = int(round(datalen/CHUNKSIZE+.5))
chunks = []
cs = 0

print("Length: %d, %d %d-byte chunks"%(datalen, nchunks, CHUNKSIZE))

while len(chunks) < nchunks:
    chunk = d[cs:cs+CHUNKSIZE].ljust(CHUNKSIZE, b"\x01")
    cs += CHUNKSIZE
    chunks.append(chunk)

addrs = [b58enc(x+dsha(x)[:4]) for x in chunks]

for addr in addrs[::-1]:
    print(addr)
