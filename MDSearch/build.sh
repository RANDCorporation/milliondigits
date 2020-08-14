#!/bin/sh

set -x
mvn clean install
builddir=MDSearch-`date +%F`
rm -rf ${builddir} ${builddir}.zip
mkdir -p ${builddir}/lib
cp target/MDSearch*.jar ${builddir}
cp target/lib/*.jar ${builddir}/lib
(cd ..; sqlite3 ./MDSearch/${builddir}/milliondigits.sqlite < import.sql)
zip -r9 ${builddir}.zip ${builddir}
rm -rf ${builddir}

