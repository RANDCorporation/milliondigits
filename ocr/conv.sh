mkdir -p step1
# pdfimages -png MR1418.digits.pdf step1/src
# pdftoppm -png MR1418.digits.pdf step1/src
mkdir -p step2
for f in step1/*.png
do
	echo $f
	outfile="step2/`basename ${f}`"
	test -e ${outfile} || convert -monochrome ${f} ${outfile}
done

mkdir -p step3
for f in step2/*.png
do
	echo $f
	outfile="step3/`basename ${f}`"
	outfile_txt="${outfile}.txt"
	test -e ${outfile_txt} || convert ${f} -define connected-components:verbose=true -connected-components 8 -auto-level ${outfile} > ${outfile_txt}
done

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

