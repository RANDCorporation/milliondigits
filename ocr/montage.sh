#!/bin/sh

test -e digits || exit "You must run conv.sh first"

mkdir montage

for digit in 0 1 2 3 4 5 6 7 8 9 Q
do
	if test ! -e digits/${digit}
	then
		echo "Digit digits/${digit} not found"
		continue
	fi
	echo "Digit ${digit}"
	mont_fldr="montage/mont_${digit}"
	cp -r digits/${digit} ${mont_fldr}
	for idx in a b c d e f g h i j
	do
		test "$(ls -A ${mont_fldr}/*.png 2>/dev/null)" || continue
		echo " -> ${idx}"
		folder="${mont_fldr}/${idx}"
		mkdir -p ${folder}
		ls -1 ${mont_fldr} | grep png | head -1024 | xargs --replace={} mv ${mont_fldr}/{} ${folder}
		montage -tile 32x -geometry +0+0 ${folder}/*.png montage/${digit}_${idx}.png
	done
done
