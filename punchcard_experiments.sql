
-- How could we switch two cards to fix the sequencing error?
-- Find two cards with the same first digit
--   - One card ends with a 4 with 1 on the next card
--   - Another card that ends with a 9 with a 4 on the next card
-- Swap them.
-- There's a parallel version where the change is at the start of a card,
--   but overall "switch two cards and everything else is the same" is
--   vanishingly unlikely compared to the next approach.

INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('sequence_switch_cards', 'Switched pairs of cards for sequencing',
   'For all the simulated punchcards, look for sample solutions to the sequence-of-two-digits question by switching two cards');

CREATE VIEW sequence_switch_cards AS
WITH pc_50k AS (SELECT * FROM punchcards WHERE endid<=50000),
         my_cards AS (SELECT pc_50k.*,
    SUBSTR(LAG(pc_50k.card_digits) OVER(PARTITION BY pc_50k.cardwidth ORDER BY pc_50k.startid ASC), pc_50k.cardwidth)  AS prev_last,
    SUBSTR(pc_50k.card_digits, pc_50k.cardwidth) AS last,
    SUBSTR(LEAD(pc_50k.card_digits) OVER(PARTITION BY pc_50k.cardwidth ORDER BY pc_50k.startid ASC), pc_50k.cardwidth) AS next_1
     FROM pc_50k),
card_switch_candidates AS (SELECT * FROM my_cards
WHERE (last='4' AND next_1='4') OR (last='9' AND next_1='1'))
SELECT csc_1.cardwidth, csc_1.cardnum AS card1, csc_1.prev_last AS prev_last_card1,
       csc_1.last AS last_card1, csc_1.next_1 AS next_card1,
       csc_2.cardnum AS card2, csc_2.prev_last AS prev_last_card2,
       csc_2.last AS last_card2, csc_2.next_1 AS next_card2
    FROM card_switch_candidates csc_1
        INNER JOIN card_switch_candidates csc_2 ON csc_1.cardwidth=csc_2.cardwidth
               AND csc_1.prev_last=csc_2.prev_last AND csc_1.last<csc_2.last
ORDER BY card1;


-- Fix a sequencing error with a single card move:
-- Most plausible story is one card out of order, so look for
--    examples.
-- Notionally, look for adjacent pairs of cards in the deck. Pairs should
--    either have "9,1" or "4,4" on their boundaries. Then, take one
--    item from one pair, and insert it between the other pair.
--    [Also must consider the digits at the other ends]
-- This gives four categories of examples, we'll look for separately:
--  (A is any digit)

-- Category 1:
--      v-- break this pair
-- xxxx4 4xxx4 Axxxx
--         ^-- move this card
--              to here --v
--                   xxxx9 1xxxx
-- 44 4A 91 becomes 4A 94 41

-- Category 2:
--            v-- break this pair
-- xxxxA 4xxx4 4xxxx
--         ^-- move this card
--              to here --v
--                   xxxx9 1xxxx
-- A4 44 91 becomes A4 94 41

-- Category 3:
--      v-- break this pair
-- xxxx9 1xxx4 4xxxx
--         ^-- move this card
--              to here --v
--                   xxxx4 4xxxx
-- 91 44 44 becomes 94 41 44

-- Category 4:
--            v-- break this pair
-- xxxx4 4xxx9 1xxxx
--         ^-- move this card
--              to here --v
--                   xxxx4 4xxxx
-- 44 91 44 becomes 41 44 94

INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('sequence_move_one_card', 'Single moved cards of cards for sequencing',
   'For all the simulated punchcards, look for sample solutions to the sequence-of-two-digits question by having a single card out of place');

CREATE VIEW sequence_move_one_card AS
WITH my_cards AS (SELECT punchcards.*,
    CAST(SUBSTR(LAG(punchcards.card_digits) OVER(PARTITION BY punchcards.cardwidth ORDER BY punchcards.startid ASC), punchcards.cardwidth) AS INTEGER) AS prev_last,
    CAST(SUBSTR(punchcards.card_digits, 1, 1) AS INTEGER) AS first_digit,
    CAST(SUBSTR(punchcards.card_digits, punchcards.cardwidth) AS INTEGER) AS last_digit,
    CAST(SUBSTR(LEAD(punchcards.card_digits) OVER(PARTITION BY punchcards.cardwidth ORDER BY punchcards.startid ASC), punchcards.cardwidth) AS INTEGER) AS next_first
     FROM punchcards WHERE startid<50000),
  insertpoint_cat12 AS (SELECT * FROM my_cards WHERE prev_last=9 AND first_digit=1),
  insertpoint_cat34 AS (SELECT * FROM my_cards WHERE prev_last=4 AND first_digit=4),
  insertpoints AS (SELECT 1 AS category, * FROM insertpoint_cat12
          UNION ALL
                   SELECT 2 AS category, * FROM insertpoint_cat12
          UNION ALL
                   SELECT 3 AS category, * FROM insertpoint_cat34
          UNION ALL
                   SELECT 4 AS category, * FROM insertpoint_cat34),
  breakpoint_cat1 AS (SELECT * FROM my_cards WHERE prev_last=4 AND first_digit=4 AND last_digit=4),
  breakpoint_cat2 AS (SELECT * FROM my_cards WHERE first_digit=4 AND last_digit=4 AND next_first=4),
  breakpoint_cat3 AS (SELECT * FROM my_cards WHERE prev_last=9 AND first_digit=1 AND last_digit=4 AND next_first=4),
  breakpoint_cat4 AS (SELECT * FROM my_cards WHERE prev_last=4 AND first_digit=4 AND last_digit=9 AND next_first=1),
  breakpoints AS (SELECT 1 AS category, * FROM breakpoint_cat1
          UNION ALL
                  SELECT 2 AS category, * FROM breakpoint_cat2
          UNION ALL
                  SELECT 3 AS category, * FROM breakpoint_cat3
          UNION ALL
                  SELECT 4 AS category, * FROM breakpoint_cat4)
SELECT ip.category, ip.cardwidth, bp.cardnum AS take_card, ip.cardnum AS insert_before
  FROM insertpoints ip INNER JOIN breakpoints bp ON bp.category=ip.category AND bp.cardwidth=ip.cardwidth
  ORDER BY ip.category, ip.cardwidth, bp.cardnum, ip.cardnum;


INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('sequence_move_one_card_digits', 'Digits of cards moved according to single-card-out-of-place above',
   'Re-simulate the punch deck with the reordered cards from sequence_move_one_card');

-- Criminially naive and is the slowest SQL query I've ever written
CREATE VIEW sequence_move_one_card_digits AS WITH RECURSIVE
     -- Calculate the new order of the deck for all cards, in the sequence_move_one_card world
     -- Read as "The card at cardnum in the newly ordered deck is the card that was previously at new_cardnum"
     reordercards AS (SELECT pm.cardwidth AS cardwidth, take_card, insert_before, startid, endid, cardnum,
       CASE WHEN (take_card>insert_before) THEN (
           CASE
               WHEN cardnum=insert_before THEN take_card
               WHEN cardnum<=take_card AND cardnum>insert_before THEN cardnum-1
               ELSE cardnum END
           )
        ELSE (
           CASE
               WHEN cardnum=insert_before THEN take_card
               WHEN cardnum>=take_card AND cardnum<insert_before THEN cardnum+1
               ELSE cardnum END
           ) END AS new_cardnum
     FROM sequence_move_one_card pm INNER JOIN punchcard_ranges pr ON pr.cardwidth=pm.cardwidth),
  -- Join the previous CTE to itself to get the digit ranges
 reordered_cards AS (SELECT ro_orig.*, ro_new.startid AS newstartid, ro_new.endid AS newendid
   FROM reordercards ro_orig
   INNER JOIN reordercards ro_new ON
       ro_new.cardwidth=ro_orig.cardwidth AND ro_new.take_card=ro_orig.take_card
       AND ro_new.insert_before=ro_orig.insert_before AND ro_new.cardnum=ro_orig.new_cardnum),
  -- Bring in all the actual digits and renumber them
 reordered_digits AS (SELECT ro.*, digits.id AS digitid, digits.digit,
       ROW_NUMBER() OVER (PARTITION BY cardwidth, take_card, insert_before ORDER BY cardnum, digits.id) AS new_digit_id
   FROM reordered_cards ro
    INNER JOIN digits ON newstartid<=digits.id AND newendid>=digits.id
    -- WHERE digits.id<=50000
)
SELECT * FROM reordered_digits
    ORDER BY cardwidth, take_card, insert_before, new_digit_id;


INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('punchcards_seq_poker_compare', 'Poker with re-simulated punchcards',
   'For the re-simulated punchcard deck, count up poker solutions');

-- It's not speedy.
--  Materialise sequence_move_one_card_digits and change this query if you actually want to run it
CREATE VIEW IF NOT EXISTS punchcards_seq_poker_compare AS
WITH
 count_each_digit AS
     (SELECT take_card, insert_before, cardwidth, (new_digit_id-1)/5 AS id, digit, COUNT(*) AS cnt, GROUP_CONCAT(digit) AS cards
     FROM sequence_move_one_card_digits GROUP BY take_card, insert_before, cardwidth, (new_digit_id-1)/5, digit),
 bust(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'bust', take_card, insert_before, cardwidth, (new_digit_id-1)/5, GROUP_CONCAT(digit) AS cards
       FROM sequence_move_one_card_digits GROUP BY take_card, insert_before, cardwidth, (new_digit_id-1)/5
       HAVING COUNT(DISTINCT digit)=5),
 pair(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'pair', take_card, insert_before, cardwidth, (new_digit_id-1)/5, GROUP_CONCAT(digit) AS cards
       FROM sequence_move_one_card_digits GROUP BY take_card, insert_before, cardwidth, (new_digit_id-1)/5
       HAVING COUNT(DISTINCT digit)=4),
 twopair(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'twopair', take_card, insert_before, cardwidth, id, GROUP_CONCAT(cards) AS cards
       FROM count_each_digit GROUP BY take_card, insert_before, cardwidth, id
       HAVING SUM(CASE WHEN 2=cnt THEN 1 ELSE 0 END)=2),
 three(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'three', take_card, insert_before, cardwidth, id, GROUP_CONCAT(cards) AS cards
       FROM count_each_digit GROUP BY take_card, insert_before, cardwidth, id
       HAVING MAX(cnt)=3 AND COUNT(DISTINCT digit)=3),
 fullhouse(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'fullhouse', take_card, insert_before, cardwidth, id, GROUP_CONCAT(cards) AS cards
       FROM count_each_digit GROUP BY take_card, insert_before, cardwidth, id
       HAVING MAX(cnt)=3 AND MIN(cnt)=2),
 four(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'four', take_card, insert_before, cardwidth, id, GROUP_CONCAT(cards) AS cards
       FROM count_each_digit GROUP BY take_card, insert_before, cardwidth, id
       HAVING MAX(cnt)=4),
 five(hand, take_card, insert_before, cardwidth, id, cards) AS
     (SELECT 'five', take_card, insert_before, cardwidth, (new_digit_id-1)/5, GROUP_CONCAT(digit) AS cards
       FROM sequence_move_one_card_digits GROUP BY take_card, insert_before, cardwidth, (new_digit_id-1)/5
       HAVING COUNT(DISTINCT digit)=1),
     allhands_cnt AS (
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM bust GROUP BY take_card, hand, insert_before, cardwidth
         UNION ALL
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM pair GROUP BY take_card, hand, insert_before, cardwidth
         UNION ALL
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM twopair GROUP BY take_card, hand, insert_before, cardwidth
         UNION ALL
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM three GROUP BY take_card, hand, insert_before, cardwidth
         UNION ALL
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM fullhouse GROUP BY take_card, hand, insert_before, cardwidth
         UNION ALL
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM four GROUP BY take_card, hand, insert_before, cardwidth
         UNION ALL
         SELECT hand, take_card, insert_before, cardwidth, COUNT(*) AS cnt FROM five GROUP BY take_card, hand, insert_before, cardwidth)
SELECT allhands_cnt.*,
       mr1418_poker_total.expected_cnt AS expected, mr1418_poker_total.cnt AS orig_cnt,
       allhands_cnt.cnt-mr1418_poker_total.cnt AS delta, abs(allhands_cnt.cnt-mr1418_poker_total.cnt) AS abs_delta
  FROM allhands_cnt INNER JOIN mr1418_poker_total ON mr1418_poker_total.hand=allhands_cnt.hand
   ORDER BY cardwidth, take_card, insert_before, hand;



INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('punchcards_seq_runs_compare', 'Runs with re-simulated punchcards',
   'For the re-simulated punchcard deck, count up runs');

-- It's not speedy.
--  Materialise sequence_move_one_card_digits and change this query if you actually want to run it
CREATE VIEW IF NOT EXISTS punchcards_seq_runs_compare AS
WITH runs AS (SELECT cardwidth, take_card, insert_before, new_digit_id, digit, new_digit_id AS start, 1 AS runlen
          FROM sequence_move_one_card_digits s WHERE new_digit_id=1
      UNION ALL
       SELECT s.cardwidth, s.take_card, s.insert_before, s.new_digit_id, s.digit,
              CASE WHEN s.digit=r.digit THEN start ELSE s.new_digit_id END,
              CASE WHEN s.digit=r.digit THEN runlen+1 ELSE 1 END
            FROM sequence_move_one_card_digits s INNER JOIN runs r ON s.new_digit_id=r.new_digit_id+1
                AND r.cardwidth=s.cardwidth AND r.take_card=s.take_card AND r.insert_before=s.insert_before
            WHERE s.new_digit_id<=50000),
     longestrun_bystart AS (SELECT cardwidth, take_card, insert_before, digit, start, MAX(runlen) AS runlen FROM runs
                GROUP BY cardwidth, take_card, insert_before, digit, start
     ),
     runcounts AS (SELECT cardwidth, take_card, insert_before, runlen, COUNT(*) AS cnt FROM longestrun_bystart
        GROUP BY cardwidth, take_card, insert_before, runlen)
SELECT runcounts.*, mr1418_runs.expected_cnt, mr1418_runs.cnt, (runcounts.cnt-mr1418_runs.cnt) AS delta
   FROM runcounts INNER JOIN mr1418_runs ON mr1418_runs.runlen=runcounts.runlen;


INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
   ('punchcard_endruns', 'Runs of digits at start and ends of cards',
	'Count parts of runs at the start and end of each card');

CREATE VIEW IF NOT EXISTS punchcard_endruns AS
WITH punchcard_ends AS (SELECT cardwidth, cardnum, startid, endid, digit, 1 AS len FROM punchcard_ranges
        INNER JOIN digits ON digits.id=endid WHERE endid<=50000
    UNION ALL
       SELECT cardwidth, cardnum, startid, endid, punchcard_ends.digit, len+1 FROM punchcard_ends
        INNER JOIN digits ON digits.id=endid-len AND digits.digit=punchcard_ends.digit),
 punchcard_starts AS (SELECT cardwidth, cardnum, startid, endid, digit, 1 AS len FROM punchcard_ranges
        INNER JOIN digits ON digits.id=startid WHERE endid<=50000
    UNION ALL
       SELECT cardwidth, cardnum, startid, endid, punchcard_starts.digit, len+1 FROM punchcard_starts
        INNER JOIN digits ON digits.id=startid+len AND digits.digit=punchcard_starts.digit
        ),
 punchcard_edges AS (
       SELECT s.cardwidth, s.cardnum,
                MIN(s.digit) AS start_digit, MAX(s.len) AS start_len,
                MIN(e.digit) AS end_digit, MAX(e.len) AS end_len
         FROM punchcard_starts s INNER JOIN punchcard_ends e ON s.cardnum=e.cardnum AND s.cardwidth=e.cardwidth
            GROUP BY s.cardwidth, s.cardnum
    )
SELECT * FROM punchcard_edges;

