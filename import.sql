-- This code creates the main tables and imports from the original data files

CREATE TABLE IF NOT EXISTS digits_row (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, page INTEGER NOT NULL,
	orig_rowtext TEXT NOT NULL, rowtext TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS digits_tuples (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, colnum INTEGER NOT NULL, val INTEGER, t TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS digits (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, colnum INTEGER NOT NULL, colidx INTEGER, digit INTEGER, t TEXT NOT NULL);

-- SQLite lacks comments in-schema, so for some things, manually document it in a table
CREATE TABLE IF NOT EXISTS view_description
  (view_name TEXT NOT NULL, long_name TEXT NOT NULL, description TEXT NOT NULL, UNIQUE(view_name));

-- SQLite allows triggers on views. So the approach is to create a dummy
--   view then import use recursive triggers to slice and dice each row
CREATE TEMPORARY VIEW IF NOT EXISTS digits_insview AS SELECT 'nothing' AS record;
CREATE TEMPORARY TRIGGER IF NOT EXISTS trig_digits_insview INSTEAD OF INSERT ON digits_insview FOR EACH ROW BEGIN
  INSERT OR IGNORE INTO digits_row (rownum, page, orig_rowtext, rowtext) VALUES
     (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 1+(CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER)/50),
              SUBSTR(NEW.record, 9), REPLACE(SUBSTR(NEW.record, 9), ' ', ''));
  INSERT OR IGNORE INTO digits_tuples (rownum, colnum, t) VALUES
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 0, SUBSTR(NEW.record,  9, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 1, SUBSTR(NEW.record, 15, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 2, SUBSTR(NEW.record, 22, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 3, SUBSTR(NEW.record, 28, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 4, SUBSTR(NEW.record, 35, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 5, SUBSTR(NEW.record, 41, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 6, SUBSTR(NEW.record, 48, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 7, SUBSTR(NEW.record, 54, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 8, SUBSTR(NEW.record, 61, 5)),
       (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 9, SUBSTR(NEW.record, 67, 5));
END;

CREATE TEMPORARY TRIGGER IF NOT EXISTS trig_single_digit_ins AFTER INSERT ON digits_tuples FOR EACH ROW BEGIN
   INSERT OR IGNORE INTO digits (rownum, colnum, colidx, t) VALUES
       (NEW.rownum, NEW.colnum, 0, SUBSTR(NEW.t, 1, 1)),
       (NEW.rownum, NEW.colnum, 1, SUBSTR(NEW.t, 2, 1)),
       (NEW.rownum, NEW.colnum, 2, SUBSTR(NEW.t, 3, 1)),
       (NEW.rownum, NEW.colnum, 3, SUBSTR(NEW.t, 4, 1)),
       (NEW.rownum, NEW.colnum, 4, SUBSTR(NEW.t, 5, 1));
END;

.import 'digits.txt' digits_insview

-- Once done, all the data is stored in textual columns. Create the numeric data
UPDATE digits_tuples SET val=CAST(t AS INTEGER);
UPDATE digits SET digit=CAST(t AS INTEGER);


-- Same approach for the standard deviates
CREATE TABLE IF NOT EXISTS deviates_row (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, page INTEGER NOT NULL,
        orig_rowtext TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS deviates (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, colnum INTEGER NOT NULL,
        val REAL, t TEXT NOT NULL);

CREATE TEMPORARY VIEW IF NOT EXISTS deviates_insview AS SELECT 'nothing' AS record;
CREATE TEMPORARY TRIGGER IF NOT EXISTS trig_deviates_insview INSTEAD OF INSERT ON deviates_insview FOR EACH ROW BEGIN
   INSERT OR IGNORE INTO deviates_row (rownum, page, orig_rowtext) VALUES
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 1+CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER)/50, SUBSTR(NEW.record, 7));
   INSERT OR IGNORE INTO deviates(rownum, colnum, t) VALUES
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 0, SUBSTR(NEW.record,  7, 7)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 1, SUBSTR(NEW.record, 14, 7)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 2, SUBSTR(NEW.record, 21, 8)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 3, SUBSTR(NEW.record, 29, 7)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 4, SUBSTR(NEW.record, 36, 8)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 5, SUBSTR(NEW.record, 44, 7)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 6, SUBSTR(NEW.record, 51, 8)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 7, SUBSTR(NEW.record, 59, 7)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 8, SUBSTR(NEW.record, 66, 8)),
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 9, SUBSTR(NEW.record, 74, 7));
END;

.import 'deviates.txt' deviates_insview

UPDATE deviates SET val=(CASE WHEN SUBSTR(t,-1)='-' THEN -1 ELSE 1 END) * CAST(SUBSTR(t, 1, LENGTH(t)-1) AS REAL);

CREATE UNIQUE INDEX IF NOT EXISTS idx_digits_row ON digits_row(rownum);
CREATE UNIQUE INDEX IF NOT EXISTS idx_digits_tuples ON digits_tuples(rownum, colnum);
CREATE UNIQUE INDEX IF NOT EXISTS idx_digits_rci ON digits(rownum, colnum, colidx);
CREATE INDEX IF NOT EXISTS idx_digits_rcd ON digits(rownum, colnum, digit);
CREATE INDEX IF NOT EXISTS idx_digits_t ON digits(t);
CREATE INDEX IF NOT EXISTS idx_digits_d ON digits(digit);

CREATE UNIQUE INDEX IF NOT EXISTS idx_deviates_row ON deviates_row(rownum);
CREATE UNIQUE INDEX IF NOT EXISTS idx_deviates ON deviates(rownum, colnum);
CREATE INDEX IF NOT EXISTS idx_deviates_val ON deviates(val);

ANALYZE;


-- To look for strings of numbers: Insert the search string into searchvals,
--   then SELECT from dosearch
CREATE TABLE IF NOT EXISTS searchvals (searchval TEXT NOT NULL, UNIQUE(searchval));
CREATE VIEW IF NOT EXISTS dosearch AS
WITH RECURSIVE q(q) AS (SELECT searchval FROM searchvals), 
  search AS (SELECT q.q AS q, id AS startid, digits.rownum AS startrownum,
        1 AS depth, id AS lastid, digits.t AS t_sofar, 0 AS found
    FROM digits,q WHERE SUBSTR(q.q, 1, 1)=digits.t
 UNION ALL
     SELECT q, startid, startrownum, depth+1, digits.id,
        search.t_sofar || digits.t, depth+1=LENGTH(q) AS found
    FROM search INNER JOIN digits ON digits.id=search.lastid+1
         WHERE SUBSTR(search.q, depth+1, 1)=digits.t
   )
SELECT * FROM ( 
  SELECT found, q, t_sofar, startid, ROW_NUMBER() OVER (PARTITION BY startid, q ORDER BY DEPTH desc) AS matchrank,
       depth AS matchlen, rownum, page, orig_rowtext
    FROM search INNER JOIN digits_row ON digits_row.rownum=search.startrownum)
  WHERE matchrank=1 
  ORDER BY matchlen DESC;

-- Render a poor man's historgram of the normal deviates
CREATE VIEW IF NOT EXISTS deviates_hist AS
WITH params(max_bar_length, bucket_width) AS (SELECT 80, 0.2),
 createbar(b) AS (SELECT '#' UNION ALL SELECT b || '#' FROM createbar, params WHERE LENGTH(b)<=max_bar_length),
 bar(b) AS (SELECT b FROM createbar ORDER BY LENGTH(b) DESC LIMIT 1),
 buckets(b_min, b_max) AS (SELECT MIN(val)-bucket_width, MIN(val) FROM deviates, params
   UNION ALL SELECT b_min+bucket_width, b_max+bucket_width FROM buckets, params
         WHERE b_min<=(SELECT MAX(val)+bucket_width FROM deviates)),
 counts(b_min, b_max, b_label, cnt, maxcnt, barheight) AS (SELECT b_min, b_max, SUBSTR('   ' || ROUND((b_min+b_max)/2.0, 1), -4),
        COUNT(*), MAX(COUNT(*)) OVER (), (max_bar_length*COUNT(*)/(MAX(COUNT(*)) OVER ()))
	FROM params, buckets LEFT JOIN deviates ON deviates.val<=buckets.b_max AND deviates.val>buckets.b_min
	GROUP BY b_min)
SELECT b_label AS x, 
   CASE WHEN cnt=0 THEN ' ' WHEN barheight=0 THEN '.' ELSE SUBSTR(b, 1, barheight) END AS bar,
	'           ' || cnt AS n
   FROM params, bar, counts
   ORDER BY b_min;


.read "punchcards.sql"
.read "original_results.sql"

.read "reproduce_results.sql"
.read "results_compare_original.sql"

