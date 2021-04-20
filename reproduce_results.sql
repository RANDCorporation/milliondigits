-- Recreations of the original analysis


-- Chi-squared calculation on blocks of fifty thousand digits
CREATE VIEW IF NOT EXISTS digit_freqs_50k AS
WITH params AS (SELECT 1000 AS rows_per_block,50 AS digits_per_row,10 AS n_digits -- A thousand rows of fifty digits each
    )
  SELECT 1+rownum/rows_per_block AS blocknum,digit,
     CAST(rows_per_block * digits_per_row AS REAL)/ n_digits AS expected,
     CAST(COUNT(*) AS REAL) AS cnt
   FROM params, digits GROUP BY rows_per_block, (rownum/ rows_per_block), digit;

CREATE VIEW IF NOT EXISTS digit_freqs_50k_wide AS
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
CREATE VIEW IF NOT EXISTS pokertotals AS SELECT hand, COUNT(*) AS cnt FROM poker GROUP BY hand;

CREATE VIEW IF NOT EXISTS pokertotals_wide AS
SELECT COUNT(bust) AS busts, COUNT(pair) AS pairs, COUNT(twopair) AS twopairs,
       COUNT(three) AS threes, COUNT(fullhouse) AS fullhouses, COUNT(four) AS fours, COUNT(five) AS fives,
       COUNT(bust)+COUNT(pair)+COUNT(twopair)+COUNT(three)+COUNT(fullhouse)+COUNT(four)+COUNT(five) AS totalhands
FROM poker;

-- Divide numbers up into ten blocks, then do variance and mean on the poker values
CREATE VIEW IF NOT EXISTS poker_variance AS
WITH params AS (SELECT 10 AS num_blocks, COUNT(*) AS num_rows FROM digits_row),
    hands_per_block AS (SELECT rownum/(num_rows/num_blocks) AS blocknum, hand,
       CAST(COUNT(*) AS REAL) AS cnt,
       AVG(COUNT(*)) OVER (PARTITION BY hand) AS mean,
       COUNT(*)-AVG(COUNT(*)) OVER (PARTITION BY hand) AS difference
        FROM params, poker GROUP BY hand, rownum/(num_rows/num_blocks))
SELECT hand, AVG(cnt) AS mean, SUM(difference*difference)/num_blocks AS variance, SUM(cnt) AS total
    FROM hands_per_block,params GROUP BY hand;

-- SQLite doesn't have SQRT() built in; use Newton-Raphson approximation to get stddev
CREATE VIEW IF NOT EXISTS poker_stddev AS
WITH RECURSIVE newtonraphson AS (SELECT 1 AS iterations, hand, mean, variance, total,
                variance/2.0 AS estimate_stddev, 1e-10 AS desired_accuracy FROM poker_variance
    UNION ALL SELECT 1+iterations, hand, mean, variance, total,
           (estimate_stddev+variance/estimate_stddev)/2.0, desired_accuracy
        FROM newtonraphson
    WHERE ABS(variance-(estimate_stddev*estimate_stddev))>desired_accuracy)
SELECT hand, total, mean, variance, estimate_stddev AS stddev FROM newtonraphson nr
   WHERE iterations=(SELECT MAX(iterations) FROM newtonraphson WHERE nr.hand=newtonraphson.hand);

-- Look at pairs of first 50k digits

-- Naively, this leads to one additional 4,4 but one fewer 4,1
-- Looping around from 50,000 to 1 for pairing adds the "error" of an additional 9,1 rather than a 9,4
-- But that does mean that a transpostion:
--  X41_____X94 [with X the same]
--   switch 4 and 9:
--  X91_____X44
-- Would generate an error making this consistent with observed frequencies

CREATE VIEW IF NOT EXISTS digitpairs_50k AS
SELECT d1.digit AS digit1, d2.digit AS digit2, COUNT(*) AS cnt
FROM digits d1 INNER JOIN digits d2 ON (CASE WHEN d1.id=50000 THEN 1 ELSE d1.id+1 END)=d2.id
 WHERE d1.id<=50000
 GROUP BY d1.digit, d2.digit;

-- SQLite doesn't have PIVOT() built in
CREATE VIEW IF NOT EXISTS digitpairs_50k_wide AS
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

-- Length of runs
CREATE VIEW IF NOT EXISTS runs AS
WITH RECURSIVE runs(start, d, runlen) AS (SELECT id, digit, 1 FROM digits WHERE id=1
 UNION ALL SELECT (CASE WHEN runs.d=digits.digit THEN start ELSE digits.id END),
                  digits.digit,
                (CASE WHEN runs.d=digits.digit THEN runlen+1 ELSE 1 END)
                FROM runs INNER JOIN digits ON runs.start+runlen=digits.id
                 WHERE digits.id<=50000),
     longestrun_bystart(start, d, runlen) AS (SELECT start, d, MAX(runlen) FROM runs GROUP BY start, d)
    SELECT runlen, COUNT(*) AS cnt FROM longestrun_bystart
    GROUP BY runlen ORDER BY runlen ASC;

