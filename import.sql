CREATE TABLE IF NOT EXISTS digits_row (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, page INTEGER NOT NULL,
	orig_rowtext TEXT NOT NULL, rowtext TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS digits_tuples (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, colnum INTEGER NOT NULL, val INTEGER, t TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS digits (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, colnum INTEGER NOT NULL, colidx INTEGER, digit INTEGER, t TEXT NOT NULL);

CREATE VIEW IF NOT EXISTS digits_insview AS SELECT 'nothing' AS record;
CREATE TRIGGER IF NOT EXISTS trig_digits_insview INSTEAD OF INSERT ON digits_insview FOR EACH ROW BEGIN
  INSERT INTO digits_row (rownum, page, orig_rowtext, rowtext) VALUES
     (CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER), 1+(CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER)/50),
              SUBSTR(NEW.record, 9), REPLACE(SUBSTR(NEW.record, 9), ' ', ''));
  INSERT INTO digits_tuples (rownum, colnum, t) VALUES
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

CREATE TRIGGER IF NOT EXISTS trig_single_digit_ins AFTER INSERT ON digits_tuples FOR EACH ROW BEGIN
   INSERT INTO digits (rownum, colnum, colidx, t) VALUES
       (NEW.rownum, NEW.colnum, 0, SUBSTR(NEW.t, 1, 1)),
       (NEW.rownum, NEW.colnum, 1, SUBSTR(NEW.t, 2, 1)),
       (NEW.rownum, NEW.colnum, 2, SUBSTR(NEW.t, 3, 1)),
       (NEW.rownum, NEW.colnum, 3, SUBSTR(NEW.t, 4, 1)),
       (NEW.rownum, NEW.colnum, 4, SUBSTR(NEW.t, 5, 1));
END;

.import 'digits.txt' digits_insview

UPDATE digits_tuples SET val=CAST(t AS INTEGER);
UPDATE digits SET digit=CAST(t AS INTEGER);

CREATE TABLE IF NOT EXISTS deviates_row (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, page INTEGER NOT NULL,
        orig_rowtext TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS deviates (id INTEGER PRIMARY KEY, rownum INTEGER NOT NULL, colnum INTEGER NOT NULL,
        val REAL, t TEXT NOT NULL);

CREATE VIEW IF NOT EXISTS deviates_insview AS SELECT 'nothing' AS record;
CREATE TRIGGER IF NOT EXISTS trig_deviates_insview INSTEAD OF INSERT ON deviates_insview FOR EACH ROW BEGIN
   INSERT INTO deviates_row (rownum, page, orig_rowtext) VALUES
        (CAST(SUBSTR(NEW.record,1,4) AS INTEGER), 1+CAST(SUBSTR(NEW.record, 1, 5) AS INTEGER)/50, SUBSTR(NEW.record, 7));
   INSERT INTO deviates(rownum, colnum, t) VALUES
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

CREATE UNIQUE INDEX idx_digits_row ON digits_row(rownum);
CREATE UNIQUE INDEX idx_digits_tuples ON digits_tuples(rownum, colnum);
CREATE UNIQUE INDEX idx_digits_rci ON digits(rownum, colnum, colidx);
CREATE INDEX idx_digits_rcd ON digits(rownum, colnum, digit);
CREATE INDEX idx_digits_t ON digits(t);
CREATE INDEX idx_digits_d ON digits(digit);

CREATE UNIQUE INDEX idx_deviates_row ON deviates_row(rownum);
CREATE UNIQUE INDEX idx_deviates ON deviates(rownum, colnum);
CREATE INDEX idx_deviates_val ON deviates(val);

ANALYZE;


-- To look for strings of numbers: Insert the search string into searchvals,
--   then SELECT from dosearch
CREATE TABLE searchvals (searchval TEXT NOT NULL, UNIQUE(searchval));
CREATE VIEW dosearch AS
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

-- Chi-squared calculation on blocks of fifty thousand digits
CREATE VIEW IF NOT EXISTS digit_freqs_50k AS
WITH params AS (SELECT 1000 AS rows_per_block,50 AS digits_per_row,10 AS n_digits -- A thousand rows of fifty digits each
    UNION ALL SELECT 20000 AS rows_per_block, 50 AS digits_per_row, 10 AS n_digits -- The whole set
    ),
     counts_by_block AS (SELECT rows_per_block,rownum/ rows_per_block AS blocknum,digit,
                                CAST(rows_per_block * digits_per_row AS REAL)/ n_digits AS expected,
                                CAST(COUNT(*) AS REAL) AS observed
                       FROM params, digits GROUP BY rows_per_block, (rownum/ rows_per_block), digit),
     chi2 AS (SELECT rows_per_block, blocknum, SUM((observed-expected)*(observed-expected)/expected) AS chi2
        FROM counts_by_block GROUP BY blocknum, rows_per_block),
     digitcnt AS (SELECT rows_per_block,rownum/ rows_per_block    AS blocknum,
                         SUM(CASE WHEN digit=0 THEN 1 ELSE 0 END) AS "0",
                         SUM(CASE WHEN digit=1 THEN 1 ELSE 0 END) AS "1",
                         SUM(CASE WHEN digit=2 THEN 1 ELSE 0 END) AS "2",
                         SUM(CASE WHEN digit=3 THEN 1 ELSE 0 END) AS "3",
                         SUM(CASE WHEN digit=4 THEN 1 ELSE 0 END) AS "4",
                         SUM(CASE WHEN digit=5 THEN 1 ELSE 0 END) AS "5",
                         SUM(CASE WHEN digit=6 THEN 1 ELSE 0 END) AS "6",
                         SUM(CASE WHEN digit=7 THEN 1 ELSE 0 END) AS "7",
                         SUM(CASE WHEN digit=8 THEN 1 ELSE 0 END) AS "8",
                         SUM(CASE WHEN digit=9 THEN 1 ELSE 0 END) AS "9"
        FROM params, digits
        GROUP BY rownum/ rows_per_block, rows_per_block)
SELECT digitcnt.*, ROUND(chi2,3) AS chi2, chi2 AS chi2_unrounded
   FROM digitcnt INNER JOIN chi2 ON chi2.blocknum=digitcnt.blocknum AND chi2.rows_per_block = digitcnt.rows_per_block
   ORDER BY digitcnt.rows_per_block ASC, digitcnt.blocknum;

-- Imagine every group of five numbers is a poker hand
CREATE VIEW IF NOT EXISTS poker AS
WITH count_each_digit AS (SELECT rownum, colnum, digit, COUNT(*) AS cnt
            FROM digits GROUP BY rownum, colnum, digit),
     bust(r,c,x) AS (SELECT rownum, colnum, 'bust' FROM digits
            GROUP BY rownum, colnum HAVING COUNT(DISTINCT digit)=5),
     pair(r,c,x) AS (SELECT rownum, colnum, 'pair' FROM digits
            GROUP BY rownum, colnum HAVING COUNT(DISTINCT digit)=4), -- Pigeonhole principle
     twopair(r,c,x) AS (SELECT rownum, colnum, 'twopair' FROM count_each_digit
            GROUP BY rownum, colnum HAVING SUM(CASE WHEN 2=cnt THEN 1 ELSE 0 END)=2),
     three(r,c,x) AS (SELECT rownum, colnum, 'three'
            FROM count_each_digit GROUP BY rownum, colnum
            HAVING MAX(cnt)=3 AND COUNT(DISTINCT digit)=3),
     fullhouse(r,c,x) AS (SELECT rownum, colnum, 'fullhouse'
            FROM count_each_digit GROUP BY rownum, colnum
            HAVING MAX(cnt)=3 AND MIN(cnt)=2),
     four(r,c,x) AS (SELECT rownum, colnum, 'four'
            FROM count_each_digit GROUP BY rownum, colnum
            HAVING MAX(cnt)=4),
     five(r,c,x) AS (SELECT rownum, colnum, 'five'
            FROM digits GROUP BY rownum, colnum HAVING COUNT(DISTINCT digit)=1)
SELECT dt.rownum, dt.colnum, dt.t,
       COALESCE(bust.x, pair.x, twopair.x, three.x, fullhouse.x, four.x, five.x) AS hand,
       bust.x AS bust, pair.x AS pair, twopair.x AS twopair,
       three.x AS three, fullhouse.x AS fullhouse, four.x AS four, five.x AS five
        FROM digits_tuples dt
        LEFT JOIN bust ON bust.r=dt.rownum AND bust.c=dt.colnum
        LEFT JOIN pair ON pair.r=dt.rownum AND pair.c=dt.colnum
        LEFT JOIN twopair ON twopair.r=dt.rownum AND twopair.c=dt.colnum
        LEFT JOIN three ON three.r=dt.rownum AND three.c=dt.colnum
        LEFT JOIN fullhouse ON fullhouse.r=dt.rownum AND fullhouse.c=dt.colnum
        LEFT JOIN four ON four.r=dt.rownum AND four.c=dt.colnum
        LEFT JOIN five ON five.r=dt.rownum AND five.c=dt.colnum;

-- Rollup of poker totals
CREATE VIEW pokertotals AS
SELECT COUNT(bust) AS busts, COUNT(pair) AS pairs, COUNT(twopair) AS twopairs,
       COUNT(three) AS threes, COUNT(fullhouse) AS fullhouses, COUNT(four) AS fours, COUNT(five) AS fives,
       COUNT(bust)+COUNT(pair)+COUNT(twopair)+COUNT(three)+COUNT(fullhouse)+COUNT(four)+COUNT(five) AS totalhands
FROM poker;

-- Divide numbers up into ten blocks, then do variance and mean on the poker values
CREATE VIEW poker_variance AS
WITH params AS (SELECT 10 AS num_blocks, COUNT(*) AS num_rows FROM digits_row),
    hands_per_block AS (SELECT rownum/(num_rows/num_blocks) AS blocknum, hand,
       CAST(COUNT(*) AS REAL) AS cnt,
       AVG(COUNT(*)) OVER (PARTITION BY hand) AS mean,
       COUNT(*)-AVG(COUNT(*)) OVER (PARTITION BY hand) AS difference
        FROM params, poker GROUP BY hand, rownum/(num_rows/num_blocks))
SELECT hand, AVG(cnt) AS mean, SUM(difference*difference)/COUNT(*) AS variance, SUM(cnt) AS total
    FROM hands_per_block GROUP BY hand;

-- SQLite doesn't have SQRT() built in; use Newton-Raphson approximation to get stddev
CREATE VIEW poker_stddev AS
WITH RECURSIVE newtonraphson AS (SELECT 1 AS iterations, hand, mean, variance, total,
                variance/2.0 AS estimate_stddev, 1e-10 AS desired_accuracy FROM poker_variance
    UNION ALL SELECT 1+iterations, hand, mean, variance, total,
           (estimate_stddev+variance/estimate_stddev)/2.0, desired_accuracy
        FROM newtonraphson
    WHERE ABS(variance-(estimate_stddev*estimate_stddev))>desired_accuracy)
SELECT hand, total, mean, variance, estimate_stddev AS stddev FROM newtonraphson nr
   WHERE iterations=(SELECT MAX(iterations) FROM newtonraphson WHERE nr.hand=newtonraphson.hand);

-- Look at pairs of first 50k digits
CREATE VIEW digitpairs_50k AS
SELECT d1.digit AS digit1, d2.digit AS digit2, COUNT(*) AS cnt
 FROM digits d1 INNER JOIN digits d2 ON d1.id=d2.id-1
 WHERE d1.id<=50000
 GROUP BY d1.digit, d2.digit;

-- SQLite doesn't have PIVOT() built in
CREATE VIEW digitpairs_50k_transposed AS
SELECT digit1,
       SUM(CASE WHEN digit2=0 THEN cnt END) AS "0",
       SUM(CASE WHEN digit2=1 THEN cnt END) AS "1",
       SUM(CASE WHEN digit2=2 THEN cnt END) AS "2",
       SUM(CASE WHEN digit2=3 THEN cnt END) AS "3",
       SUM(CASE WHEN digit2=4 THEN cnt END) AS "4",
       SUM(CASE WHEN digit2=5 THEN cnt END) AS "5",
       SUM(CASE WHEN digit2=6 THEN cnt END) AS "6",
       SUM(CASE WHEN digit2=7 THEN cnt END) AS "7",
       SUM(CASE WHEN digit2=8 THEN cnt END) AS "8",
       SUM(CASE WHEN digit2=9 THEN cnt END) AS "9",
       SUM(cnt) AS total
FROM digitpairs_50k
 GROUP BY digit1;

