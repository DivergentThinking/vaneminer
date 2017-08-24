#!/bin/bash
INADR=1LoLoLayunp23dNqCVJ56N8MxLCLPti1B8
OUTF='image.gif'
URL="https://www.snatcoin.com/transactions.php?address=$INADR"
# https://bitcointalk.org/index.php?topic=10970.msg156708#msg156708

base58=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})

decodeBase58() {
    local s=$1
    for i in {0..57}
    do s="${s//${base58[i]}/ $i}"
    done
	lead=$(echo $s | egrep -o "^(0\ )+" | tr -d ' ' | sed 's/0/&&/g')
	s=$(dc <<< "16o0d${s// /+58*}+f")
	s="${lead}$s"
	[[ ${#s} != 50 ]] && s="0$s"
	echo $s
}

echo -n>"$OUTF"

r=0
curl "$URL" | grep -m1 yourTransactions | cut -d"'" -f2 | sed 's/},/&\n/g' | while IFS='"' read -a a; do
	[[ ${a[3]} != "$INADR" ]] && continue
	d=${a[7]}
	[[ $d = "imageDataBegins"* ]] && { r=1; continue; }
	[[ $r -eq 0 ]] && continue
	echo $d
	decodeBase58 $d | head -c42 | xxd -r -p >>$OUTF
done
