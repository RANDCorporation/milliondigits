#!/bin/sh

# Download https://www.rand.org/content/dam/rand/pubs/monograph_reports/MR1418/MR1418.digits.pdf

# The python code reads this file to decide where to create digits
echo "Creating map of id to digit"
test -e id_digit.csv || sqlite3 -csv ../milliondigits.sqlite "SELECT id, digit FROM digits;" > ./id_digit.csv

echo "Extracting PDF pages to images"
mkdir -p step1
# Extract all pdf pages as images
# test -e step1/src-145.png || pdfimages -png MR1418.digits.pdf step1/src
test -e step1/src-145.png || pdftoppm -png MR1418.digits.pdf step1/src

echo "Doing a first-pass conversion of images to get them into the ballpark"
mkdir -p step2
for f in step1/*.png
do
	# echo $f
	outfile="step2/`basename ${f}`"
	# If using pdfimages:
	# test -e ${outfile} || convert -verbose -scale 45% -rotate 90 -threshold 70% ${f} ${outfile}
	# If using pdftoppm:
	test -e ${outfile} || convert -verbose -threshold 70% ${f} ${outfile}
	# test -e ${outfile} || convert -monochrome ${f} ${outfile}
done

echo "Using imagemagick to get connected components"
mkdir -p step3
for f in step2/*.png
do
	# echo $f
	outfile="step3/`basename ${f}`"
	outfile_txt="${outfile}.txt"
	test -e ${outfile_txt} || convert -verbose ${f} -define connected-components:verbose=true -connected-components 8 -auto-level ${outfile} > ${outfile_txt}
done


echo "Running python heuristics"
python3 digits_split.py

# for f in step1/src*
# do
    # echo $f
    # outfile="step2/`basename ${f}`"
    # test -e ${outfile} || convert -monochrome -rotate 90 -scale 40% ${f} ${outfile}
# done

# mkdir -p step3
# for f in step2/src*
# do
    # echo $f
    # tesseract \
        # --user-words ./eng.user-words \
        # --user-patterns ./eng.user-patterns \
        # -c load_system_dawg=false \
        # -c load_freq_dawg=false \
        # ${f} \
        # step3/`basename ${f}` \
        # digits
        # --psm 2 \
# done

