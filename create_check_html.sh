#!/bin/sh

db=checks.sqlite
output_file=milliondigits_checks.html

echo 'Constructing db'
rm -f ${db}
cat import.sql | sqlite3 ${db}

echo '<html><head><title>Million Digits Checks</title></head><body>' > ${output_file}
echo '<h1>Comparing Million Digits Tables</h1>' >> ${output_file}
for f in `echo "SELECT name FROM sqlite_master WHERE name LIKE 'check_%';" | sqlite3 ${db}`
do
  sqlite3 ${db} "SELECT '<h2>' || long_name || '</h2>' || '<p>' || description || '</p>' FROM view_description WHERE view_name='${f}'" >> ${output_file}
  # echo "<h2>${f}</h2>" >> ${output_file}
  echo '<table cellspacing=0 cellpadding=3 border=1>' >> ${output_file}
   echo "Dropping $f"
sqlite3 -html -header ${db} "SELECT * FROM ${f};" >> ${output_file}
  echo '</table>' >> ${output_file}

done

echo '</body></html>' >> ${output_file}


