#!/usr/bin/env python3
from math import floor
import time
import binascii
import requests
import sys
from os import getpid, execv

mainpriv = "not yet"
mainpub = "1HaHaCZ6UNsDXT5ktoH2vHsyKKdxvQxRk4"

HEADERS={"Host": "www.snatcoin.com","User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0","Accept": "*/*","Accept-Language": "en-US,en;q=0.5","Accept-Encoding": "gzip, deflate, br","Referer": "https://www.snatcoin.com/","X-Requested-With": "XMLHttpRequest","DNT": "1","Connection": "close",}
URL_BASE = "https://www.snatcoin.com/"
URL_BALANCE = URL_BASE + "getbalanceB.php"
URL_UNIXT = URL_BASE + "/php/sendunixTime.php"
URL_SEND = URL_BASE + "sender52562.php"
URL_VALIDATE = URL_BASE + "validate.php"

ses = requests.Session()
balance = lambda pubkey: ses.get(URL_BALANCE,
        params={"data": pubkey}, headers=HEADERS).text
sendsnat = lambda frompriv, frompub, topub, amt:ses.get(URL_SEND,
        params={"pkey": frompriv, "xxeckey": frompub, "snatamount": amt, "recAddy": topub},
        headers=HEADERS).text
validate = lambda topub: ses.post(URL_VALIDATE, data={"str12":topub}, headers=HEADERS).text

with open("in", "r") as peepee:
    adrs = [l.strip() for l in peepee.readlines()]
#adrs = [l.strip() for l in sys.stdin.readlines()]
start=0
ctr=0
if len(sys.argv) >= 2:
    start = int(sys.argv[1])
for i, a in enumerate(adrs[start:]):
    tries = 10
    while tries > 0:
        print("#%d (%.1f%%) %s "%(i+start,(i+start)*100/len(adrs),a), end="")
        bal, val, send = "", "", ""
        try:
            bal = balance(mainpub)
            val = validate(a)
            send = sendsnat(mainpriv, mainpub, a, 0.000001)
        except requests.exception.RequestException:
            print("request err", end=" ")
            pass # too bad
        else:
            print(bal, val, send, end="")
        if val == '1' and send == '2':
            tries = 0
            print(" - success")
        else:
            tries -= 1
            print(" - failed still trying (%d tries left)")

    ctr += 1
    if ctr >= 30:
        ctr = 0
        sys.stdout.flush()
