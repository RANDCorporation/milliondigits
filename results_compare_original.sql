
CREATE VIEW IF NOT EXISTS precursor_check_freq AS
SELECT mr1418_freqs.blocknum, mr1418_freqs.digit, digit_freqs_50k.expected,
    mr1418_freqs.cnt AS orig_cnt, digit_freqs_50k.cnt AS new_cnt,
    digit_freqs_50k.cnt-mr1418_freqs.cnt AS abs_delta, (digit_freqs_50k.cnt-mr1418_freqs.cnt)/mr1418_freqs.cnt AS rel_delta
  FROM mr1418_freqs INNER JOIN digit_freqs_50k ON mr1418_freqs.blocknum=digit_freqs_50k.blocknum
    AND mr1418_freqs.digit=digit_freqs_50k.digit;


-- SQLite lacks PIVOT()
INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('check_freq', 'Table 1: Frequencies of One Million Digits',
   'In 20 blocks of 50k digits, frequencies of each digit');

CREATE VIEW IF NOT EXISTS check_freq AS
WITH q AS (SELECT blocknum
    ,SUM(CASE WHEN digit=0 THEN new_cnt END) AS new_cnt_0, SUM(CASE WHEN digit=0 THEN abs_delta END) delta_0
    ,SUM(CASE WHEN digit=1 THEN new_cnt END) AS new_cnt_1, SUM(CASE WHEN digit=1 THEN abs_delta END) delta_1
    ,SUM(CASE WHEN digit=2 THEN new_cnt END) AS new_cnt_2, SUM(CASE WHEN digit=2 THEN abs_delta END) delta_2
    ,SUM(CASE WHEN digit=3 THEN new_cnt END) AS new_cnt_3, SUM(CASE WHEN digit=3 THEN abs_delta END) delta_3
    ,SUM(CASE WHEN digit=4 THEN new_cnt END) AS new_cnt_4, SUM(CASE WHEN digit=4 THEN abs_delta END) delta_4
    ,SUM(CASE WHEN digit=5 THEN new_cnt END) AS new_cnt_5, SUM(CASE WHEN digit=5 THEN abs_delta END) delta_5
    ,SUM(CASE WHEN digit=6 THEN new_cnt END) AS new_cnt_6, SUM(CASE WHEN digit=6 THEN abs_delta END) delta_6
    ,SUM(CASE WHEN digit=7 THEN new_cnt END) AS new_cnt_7, SUM(CASE WHEN digit=7 THEN abs_delta END) delta_7
    ,SUM(CASE WHEN digit=8 THEN new_cnt END) AS new_cnt_8, SUM(CASE WHEN digit=8 THEN abs_delta END) delta_8
    ,SUM(CASE WHEN digit=9 THEN new_cnt END) AS new_cnt_9, SUM(CASE WHEN digit=9 THEN abs_delta END) delta_9
       FROM precursor_check_freq GROUP BY blocknum)
SELECT blocknum
,CAST(new_cnt_0 AS INTEGER) || CASE WHEN delta_0=0 THEN '' ELSE printf(' (%+d)', delta_0) END AS digit_0
,CAST(new_cnt_1 AS INTEGER) || CASE WHEN delta_1=0 THEN '' ELSE printf(' (%+d)', delta_1) END AS digit_1
,CAST(new_cnt_2 AS INTEGER) || CASE WHEN delta_2=0 THEN '' ELSE printf(' (%+d)', delta_2) END AS digit_2
,CAST(new_cnt_3 AS INTEGER) || CASE WHEN delta_3=0 THEN '' ELSE printf(' (%+d)', delta_3) END AS digit_3
,CAST(new_cnt_4 AS INTEGER) || CASE WHEN delta_4=0 THEN '' ELSE printf(' (%+d)', delta_4) END AS digit_4
,CAST(new_cnt_5 AS INTEGER) || CASE WHEN delta_5=0 THEN '' ELSE printf(' (%+d)', delta_5) END AS digit_5
,CAST(new_cnt_6 AS INTEGER) || CASE WHEN delta_6=0 THEN '' ELSE printf(' (%+d)', delta_6) END AS digit_6
,CAST(new_cnt_7 AS INTEGER) || CASE WHEN delta_7=0 THEN '' ELSE printf(' (%+d)', delta_7) END AS digit_7
,CAST(new_cnt_8 AS INTEGER) || CASE WHEN delta_8=0 THEN '' ELSE printf(' (%+d)', delta_8) END AS digit_8
,CAST(new_cnt_9 AS INTEGER) || CASE WHEN delta_9=0 THEN '' ELSE printf(' (%+d)', delta_9) END AS digit_9
FROM q ORDER BY blocknum;


CREATE VIEW IF NOT EXISTS precursor_check_poker AS
SELECT mr1418_poker_total.hand, mr1418_poker_total.expected_cnt, mr1418_poker_total.cnt AS orig_cnt, pokertotals.cnt AS new_cnt,
   pokertotals.cnt-mr1418_poker_total.cnt AS abs_delta, (pokertotals.cnt-mr1418_poker_total.cnt)/CAST(mr1418_poker_total.cnt AS REAL) AS rel_delta
  FROM mr1418_poker_total INNER JOIN pokertotals ON pokertotals.hand=mr1418_poker_total.hand;

INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('check_poker', 'Table 3: Poker Test on the Million Digits (200,000 Poker Hands)',
   'Digits are broken into groups of five then evaluated as poker hands');

CREATE VIEW IF NOT EXISTS check_poker AS
SELECT pcp.hand, expected_cnt, orig_cnt,
  new_cnt || CASE WHEN abs_delta=0 THEN '' ELSE PRINTF(' (%+d)', abs_delta) END AS new_cnt
FROM precursor_check_poker pcp INNER JOIN mr1418_poker_expected_per_block rnk ON pcp.hand=rnk.hand
 ORDER BY handrank ASC;



CREATE VIEW IF NOT EXISTS precursor_check_ordered_pair AS
SELECT digitpairs_50k.digit1, digitpairs_50k.digit2, mr1418_orderedpairs.cnt AS orig_cnt, digitpairs_50k.cnt AS new_cnt,
                  (digitpairs_50k.cnt-mr1418_orderedpairs.cnt) AS abs_delta,
                  (digitpairs_50k.cnt-mr1418_orderedpairs.cnt)/CAST (mr1418_orderedpairs.cnt AS REAL) AS rel_delta
     FROM digitpairs_50k INNER JOIN mr1418_orderedpairs ON
        digitpairs_50k.digit1=mr1418_orderedpairs.digit1 AND digitpairs_50k.digit2=mr1418_orderedpairs.digit2;

INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('check_ordered_pair', 'Table 5: Frequencies of Ordered Pairs of Digits',
   'Each pair of digits in the first 50,000 is tabulated to look for serial associations');

CREATE VIEW IF NOT EXISTS check_ordered_pair AS 
WITH q AS (SELECT digit1
    ,SUM(CASE WHEN digit2=0 THEN new_cnt END) AS new_cnt_0, SUM(CASE WHEN digit2=0 THEN abs_delta END) delta_0
    ,SUM(CASE WHEN digit2=1 THEN new_cnt END) AS new_cnt_1, SUM(CASE WHEN digit2=1 THEN abs_delta END) delta_1
    ,SUM(CASE WHEN digit2=2 THEN new_cnt END) AS new_cnt_2, SUM(CASE WHEN digit2=2 THEN abs_delta END) delta_2
    ,SUM(CASE WHEN digit2=3 THEN new_cnt END) AS new_cnt_3, SUM(CASE WHEN digit2=3 THEN abs_delta END) delta_3
    ,SUM(CASE WHEN digit2=4 THEN new_cnt END) AS new_cnt_4, SUM(CASE WHEN digit2=4 THEN abs_delta END) delta_4
    ,SUM(CASE WHEN digit2=5 THEN new_cnt END) AS new_cnt_5, SUM(CASE WHEN digit2=5 THEN abs_delta END) delta_5
    ,SUM(CASE WHEN digit2=6 THEN new_cnt END) AS new_cnt_6, SUM(CASE WHEN digit2=6 THEN abs_delta END) delta_6
    ,SUM(CASE WHEN digit2=7 THEN new_cnt END) AS new_cnt_7, SUM(CASE WHEN digit2=7 THEN abs_delta END) delta_7
    ,SUM(CASE WHEN digit2=8 THEN new_cnt END) AS new_cnt_8, SUM(CASE WHEN digit2=8 THEN abs_delta END) delta_8
    ,SUM(CASE WHEN digit2=9 THEN new_cnt END) AS new_cnt_9, SUM(CASE WHEN digit2=9 THEN abs_delta END) delta_9
       FROM precursor_check_ordered_pair GROUP BY digit1)
SELECT digit1
,CAST(new_cnt_0 AS INTEGER) || CASE WHEN delta_0=0 THEN '' ELSE printf(' (%+d)', delta_0) END AS digit2_0
,CAST(new_cnt_1 AS INTEGER) || CASE WHEN delta_1=0 THEN '' ELSE printf(' (%+d)', delta_1) END AS digit2_1
,CAST(new_cnt_2 AS INTEGER) || CASE WHEN delta_2=0 THEN '' ELSE printf(' (%+d)', delta_2) END AS digit2_2
,CAST(new_cnt_3 AS INTEGER) || CASE WHEN delta_3=0 THEN '' ELSE printf(' (%+d)', delta_3) END AS digit2_3
,CAST(new_cnt_4 AS INTEGER) || CASE WHEN delta_4=0 THEN '' ELSE printf(' (%+d)', delta_4) END AS digit2_4
,CAST(new_cnt_5 AS INTEGER) || CASE WHEN delta_5=0 THEN '' ELSE printf(' (%+d)', delta_5) END AS digit2_5
,CAST(new_cnt_6 AS INTEGER) || CASE WHEN delta_6=0 THEN '' ELSE printf(' (%+d)', delta_6) END AS digit2_6
,CAST(new_cnt_7 AS INTEGER) || CASE WHEN delta_7=0 THEN '' ELSE printf(' (%+d)', delta_7) END AS digit2_7
,CAST(new_cnt_8 AS INTEGER) || CASE WHEN delta_8=0 THEN '' ELSE printf(' (%+d)', delta_8) END AS digit2_8
,CAST(new_cnt_9 AS INTEGER) || CASE WHEN delta_9=0 THEN '' ELSE printf(' (%+d)', delta_9) END AS digit2_9
FROM q ORDER BY digit1;



CREATE VIEW IF NOT EXISTS precursor_check_runs AS
   SELECT mr1418_runs.runlen, mr1418_runs.expected_cnt, mr1418_runs.cnt AS orig_cnt, runs.cnt AS new_cnt,
        runs.cnt-mr1418_runs.cnt AS abs_delta, (runs.cnt-mr1418_runs.cnt)/CAST(mr1418_runs.cnt AS REAL) AS rel_delta,
       SUM(mr1418_runs.runlen*mr1418_runs.cnt) OVER () AS orig_total_digits,
       SUM(mr1418_runs.runlen*runs.cnt) OVER () AS new_total_digits
    FROM mr1418_runs INNER JOIN runs ON mr1418_runs.runlen=runs.runlen;

INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('check_runs', 'Table 6: Run Test',
   'Runs of digits in the first 50,000 are counted');

CREATE VIEW IF NOT EXISTS check_runs AS
SELECT runlen, expected_cnt, orig_cnt,
       new_cnt || CASE WHEN 0=abs_delta THEN '' ELSE PRINTF(' (%+d)', abs_delta) END AS new_cnt
  FROM precursor_check_runs ORDER BY runlen;

