-- Table 1 "Frequencies of One Million Digits"
CREATE TABLE IF NOT EXISTS mr1418_freqs (blocknum INTEGER NOT NULL, digit INTEGER NOT NULL, cnt INTEGER NOT NULL, UNIQUE(blocknum, digit));
INSERT OR IGNORE INTO mr1418_freqs (blocknum, digit, cnt) VALUES
(1, 0, 4923), (1, 1, 5013), (1, 2, 4916), (1, 3, 4951), (1, 4, 5109),
(1, 5, 4993), (1, 6, 5055), (1, 7, 5080), (1, 8, 4986), (1, 9, 4974),
(2, 0, 4870), (2, 1, 4956), (2, 2, 5080), (2, 3, 5097), (2, 4, 5066),
(2, 5, 5034), (2, 6, 4902), (2, 7, 4974), (2, 8, 5012), (2, 9, 5009),
(3, 0, 5065), (3, 1, 5014), (3, 2, 5034), (3, 3, 5057), (3, 4, 4902),
(3, 5, 5061), (3, 6, 4942), (3, 7, 4946), (3, 8, 4960), (3, 9, 5019),
(4, 0, 5009), (4, 1, 5053), (4, 2, 4966), (4, 3, 4891), (4, 4, 5031),
(4, 5, 4895), (4, 6, 5037), (4, 7, 5062), (4, 8, 5170), (4, 9, 4886),
(5, 0, 5033), (5, 1, 4982), (5, 2, 5180), (5, 3, 5074), (5, 4, 4892),
(5, 5, 4992), (5, 6, 5011), (5, 7, 5005), (5, 8, 4959), (5, 9, 4872),
(6, 0, 4976), (6, 1, 4993), (6, 2, 4932), (6, 3, 5039), (6, 4, 4965),
(6, 5, 5034), (6, 6, 4943), (6, 7, 4932), (6, 8, 5116), (6, 9, 5070),
(7, 0, 5011), (7, 1, 5152), (7, 2, 4990), (7, 3, 5047), (7, 4, 4974),
(7, 5, 5107), (7, 6, 4869), (7, 7, 4925), (7, 8, 5023), (7, 9, 4902),
(8, 0, 5003), (8, 1, 5092), (8, 2, 5163), (8, 3, 4936), (8, 4, 5020),
(8, 5, 5069), (8, 6, 4914), (8, 7, 4943), (8, 8, 4914), (8, 9, 4946),
(9, 0, 4860), (9, 1, 4899), (9, 2, 5138), (9, 3, 4959), (9, 4, 5089),
(9, 5, 5047), (9, 6, 5030), (9, 7, 5039), (9, 8, 5002), (9, 9, 4937),
(10, 0, 4998), (10, 1, 4957), (10, 2, 4964), (10, 3, 5124), (10, 4, 4909),
(10, 5, 4995), (10, 6, 5053), (10, 7, 4946), (10, 8, 4995), (10, 9, 5059),
(11, 0, 4948), (11, 1, 5048), (11, 2, 5041), (11, 3, 5077), (11, 4, 5051),
(11, 5, 5004), (11, 6, 5024), (11, 7, 4886), (11, 8, 4917), (11, 9, 5004),
(12, 0, 4958), (12, 1, 4993), (12, 2, 5064), (12, 3, 4987), (12, 4, 5041),
(12, 5, 4984), (12, 6, 4991), (12, 7, 4987), (12, 8, 5113), (12, 9, 4882),
(13, 0, 4968), (13, 1, 4961), (13, 2, 5029), (13, 3, 5038), (13, 4, 5022),
(13, 5, 5023), (13, 6, 5010), (13, 7, 4988), (13, 8, 4936), (13, 9, 5025),
(14, 0, 5110), (14, 1, 4923), (14, 2, 5025), (14, 3, 4975), (14, 4, 5095),
(14, 5, 5051), (14, 6, 5035), (14, 7, 4962), (14, 8, 4942), (14, 9, 4882),
(15, 0, 5094), (15, 1, 4962), (15, 2, 4945), (15, 3, 4891), (15, 4, 5014),
(15, 5, 5002), (15, 6, 5038), (15, 7, 5023), (15, 8, 5179), (15, 9, 4852),
(16, 0, 4957), (16, 1, 5035), (16, 2, 5051), (16, 3, 5021), (16, 4, 5036),
(16, 5, 4927), (16, 6, 5022), (16, 7, 4988), (16, 8, 4910), (16, 9, 5053),
(17, 0, 5088), (17, 1, 4989), (17, 2, 5042), (17, 3, 4948), (17, 4, 4999),
(17, 5, 5028), (17, 6, 5037), (17, 7, 4893), (17, 8, 5004), (17, 9, 4972),
(18, 0, 4970), (18, 1, 5034), (18, 2, 4996), (18, 3, 5008), (18, 4, 5049),
(18, 5, 5016), (18, 6, 4954), (18, 7, 4989), (18, 8, 4970), (18, 9, 5014),
(19, 0, 4998), (19, 1, 4981), (19, 2, 4984), (19, 3, 5107), (19, 4, 4874),
(19, 5, 4980), (19, 6, 5057), (19, 7, 5020), (19, 8, 4978), (19, 9, 5021),
(20, 0, 4963), (20, 1, 5013), (20, 2, 5101), (20, 3, 5084), (20, 4, 4956),
(20, 5, 4972), (20, 6, 5018), (20, 7, 4971), (20, 8, 5021), (20, 9, 4901);

CREATE VIEW IF NOT EXISTS precursor_check_freq AS
SELECT mr1418_freqs.blocknum, mr1418_freqs.digit, digit_freqs_50k.expected,
    mr1418_freqs.cnt AS orig_cnt, digit_freqs_50k.cnt AS new_cnt,
    digit_freqs_50k.cnt-mr1418_freqs.cnt AS abs_delta, (digit_freqs_50k.cnt-mr1418_freqs.cnt)/mr1418_freqs.cnt AS rel_delta
  FROM mr1418_freqs INNER JOIN digit_freqs_50k ON mr1418_freqs.blocknum=digit_freqs_50k.blocknum
    AND mr1418_freqs.digit=digit_freqs_50k.digit;


-- SQLite lacks PIVOT()
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


-- Table 2 "Distribution of Chi-square Values [of poker hands]"
CREATE TABLE IF NOT EXISTS mr1418_poker_chi2 (p_min REAL, p_max REAL, chi2_min REAL, chi2_max REAL,
     expected REAL NOT NULL, cnt REAL NOT NULL);
INSERT OR IGNORE INTO mr1418_poker_chi2 (p_min, p_max, chi2_min, chi2_max, expected, cnt) VALUES
(NULL,  0.9, 0.00, 1.60, 20, 22),
( 0.9,  0.8, 1.61, 2.35, 20, 19),
( 0.8,  0.7, 2.36, 3.00, 20, 22),
( 0.7,  0.6, 3.01, 3.70, 20, 19),
( 0.6,  0.5, 3.71, 4.35, 20, 20),
( 0.5,  0.4, 4.36, 5.20, 20, 29),
( 0.4,  0.3, 5.21, 6.10, 20, 22),
( 0.3,  0.2, 6.11, 7.30, 20, 15),
( 0.2,  0.1, 7.31, 9.20, 20, 15),
( 0.1, NULL, 9.21, NULL, 20, 17);

CREATE TABLE IF NOT EXISTS mr1418_poker_expected_per_block
   (hand TEXT NOT NULL, handrank INTEGER NOT NULL, symbol TEXT NOT NULL, expected REAL, UNIQUE(hand));
INSERT OR IGNORE INTO mr1418_poker_expected_per_block (hand, handrank, symbol, expected) VALUES
('bust', 1, 'abcde', 302.4),
('pair', 2, 'aabcd', 504),
('twopair', 3, 'aabbc', 108),
('three', 4, 'aaabc', 72),
('fullhouse', 5, 'aaabb', 9),
('four', 6, 'aaaab', 4.5),
('five', 7, 'aaaaa', 0.1);


-- Table 3 "Poker Test on the Million Digits (200,000 Poker Hands)"
CREATE TABLE IF NOT EXISTS mr1418_poker_total (hand TEXT NOT NULL, expected_cnt REAL NOT NULL, cnt INTEGER NOT NULL, UNIQUE(hand));
INSERT OR IGNORE INTO mr1418_poker_total (hand, expected_cnt, cnt)
   VALUES ('bust', 60480, 60479), ('pair', 100800, 100570), ('twopair', 21600, 21572),
    ('three', 14400, 14659), ('fullhouse', 1800, 1788), ('four', 900, 914), ('five', 20, 18);

CREATE VIEW IF NOT EXISTS precursor_check_poker AS
SELECT mr1418_poker_total.hand, mr1418_poker_total.expected_cnt, mr1418_poker_total.cnt AS orig_cnt, pokertotals.cnt AS new_cnt,
   pokertotals.cnt-mr1418_poker_total.cnt AS abs_delta, (pokertotals.cnt-mr1418_poker_total.cnt)/CAST(mr1418_poker_total.cnt AS REAL) AS rel_delta
  FROM mr1418_poker_total INNER JOIN pokertotals ON pokertotals.hand=mr1418_poker_total.hand;

CREATE VIEW IF NOT EXISTS check_poker AS
SELECT pcp.hand, expected_cnt, orig_cnt,
  new_cnt || CASE WHEN abs_delta=0 THEN '' ELSE PRINTF(' (%+d)', abs_delta) END AS new_cnt
FROM precursor_check_poker pcp INNER JOIN mr1418_poker_expected_per_block rnk ON pcp.hand=rnk.hand
 ORDER BY handrank ASC;


-- Table 5 "Frequencies of Ordered Pairs of Digits"
CREATE TABLE IF NOT EXISTS mr1418_orderedpairs (digit1 INTEGER NOT NULL, digit2 INTEGER NOT NULL,
     cnt INTEGER NOT NULL, UNIQUE(digit1, digit2));
INSERT OR IGNORE INTO mr1418_orderedpairs (digit1, digit2, cnt) VALUES
    (0, 0, 508), (0, 1, 456), (0, 2, 509), (0, 3, 507), (0, 4, 502),
    (0, 5, 489), (0, 6, 471), (0, 7, 504), (0, 8, 488), (0, 9, 489),
    (1, 0, 510), (1, 1, 514), (1, 2, 474), (1, 3, 514), (1, 4, 504),
    (1, 5, 481), (1, 6, 496), (1, 7, 486), (1, 8, 507), (1, 9, 527),
    (2, 0, 451), (2, 1, 523), (2, 2, 493), (2, 3, 484), (2, 4, 502),
    (2, 5, 466), (2, 6, 514), (2, 7, 506), (2, 8, 493), (2, 9, 484),
    (3, 0, 500), (3, 1, 472), (3, 2, 476), (3, 3, 466), (3, 4, 513),
    (3, 5, 478), (3, 6, 540), (3, 7, 513), (3, 8, 530), (3, 9, 463),
    (4, 0, 513), (4, 1, 561), (4, 2, 481), (4, 3, 485), (4, 4, 526),
    (4, 5, 513), (4, 6, 485), (4, 7, 510), (4, 8, 524), (4, 9, 511),
    (5, 0, 475), (5, 1, 490), (5, 2, 527), (5, 3, 507), (5, 4, 493),
    (5, 5, 481), (5, 6, 489), (5, 7, 512), (5, 8, 465), (5, 9, 554),
    (6, 0, 494), (6, 1, 486), (6, 2, 491), (6, 3, 483), (6, 4, 525),
    (6, 5, 504), (6, 6, 530), (6, 7, 539), (6, 8, 513), (6, 9, 490),
    (7, 0, 508), (7, 1, 512), (7, 2, 454), (7, 3, 498), (7, 4, 550),
    (7, 5, 533), (7, 6, 516), (7, 7, 504), (7, 8, 485), (7, 9, 520),
    (8, 0, 463), (8, 1, 503), (8, 2, 475), (8, 3, 514), (8, 4, 520),
    (8, 5, 544), (8, 6, 514), (8, 7, 491), (8, 8, 520), (8, 9, 442),
    (9, 0, 501), (9, 1, 496), (9, 2, 536), (9, 3, 493), (9, 4, 474),
    (9, 5, 504), (9, 6, 500), (9, 7, 515), (9, 8, 461), (9, 9, 494);

CREATE VIEW IF NOT EXISTS precursor_check_ordered_pair AS
SELECT digitpairs_50k.digit1, digitpairs_50k.digit2, mr1418_orderedpairs.cnt AS orig_cnt, digitpairs_50k.cnt AS new_cnt,
                  (digitpairs_50k.cnt-mr1418_orderedpairs.cnt) AS abs_delta,
                  (digitpairs_50k.cnt-mr1418_orderedpairs.cnt)/CAST (mr1418_orderedpairs.cnt AS REAL) AS rel_delta
     FROM digitpairs_50k INNER JOIN mr1418_orderedpairs ON
        digitpairs_50k.digit1=mr1418_orderedpairs.digit1 AND digitpairs_50k.digit2=mr1418_orderedpairs.digit2;

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


-- Table 6 "Run Test"
CREATE TABLE IF NOT EXISTS mr1418_runs (runlen INTEGER NOT NULL, expected_cnt REAL NOT NULL, cnt INTEGER NOT NULL, UNIQUE(runlen));
INSERT OR IGNORE INTO mr1418_runs (runlen, expected_cnt, cnt) 
   VALUES (1, 40500, 40410), (2, 4050, 4055), (3, 405, 421), (4, 40.5, 48), (5, 4.5, 5);

CREATE VIEW IF NOT EXISTS precursor_check_runs AS
   SELECT mr1418_runs.runlen, mr1418_runs.expected_cnt, mr1418_runs.cnt AS orig_cnt, runs.cnt AS new_cnt,
        runs.cnt-mr1418_runs.cnt AS abs_delta, (runs.cnt-mr1418_runs.cnt)/CAST(mr1418_runs.cnt AS REAL) AS rel_delta,
       SUM(mr1418_runs.runlen*mr1418_runs.cnt) OVER () AS orig_total_digits,
       SUM(mr1418_runs.runlen*runs.cnt) OVER () AS new_total_digits
    FROM mr1418_runs INNER JOIN runs ON mr1418_runs.runlen=runs.runlen;

CREATE VIEW IF NOT EXISTS check_runs AS
SELECT runlen, expected_cnt, orig_cnt,
       new_cnt || CASE WHEN 0=abs_delta THEN '' ELSE PRINTF(' (%+d)', abs_delta) END AS new_cnt
  FROM precursor_check_runs ORDER BY runlen;

