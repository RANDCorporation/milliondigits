#!/bin/sh
db=milliondigits.sqlite
echo "Creating ${db}"
rm -f ${db}; sqlite3 ${db} < import.sql

db_noresults=milliondigits_noresults.sqlite
echo "Creating ${db_noresults}"
rm -f ${db_noresults}; grep --before-context=50000 ANALYSIS import.sql | sqlite3 ${db_noresults}

