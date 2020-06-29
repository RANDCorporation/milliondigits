-- The digits were originally on punchcards.
-- What would this look like on its original punchcards?

CREATE TABLE IF NOT EXISTS punchcard_widths (width INTEGER NOT NULL, UNIQUE(width));
INSERT INTO punchcard_widths (width) VALUES (80);

CREATE VIEW IF NOT EXISTS punchcards AS
WITH cardwidth(width) AS (SELECT width FROM punchcard_widths),
     cardranges AS (SELECT min(id) AS startid, max(id) AS endid, (id-1)/width AS cardnum, width AS cardwidth
   FROM digits, cardwidth GROUP BY width, (id-1)/width),
digits_iter(startid, endid, cardnum, cardwidth, card_digits, len) AS
    (SELECT startid, endid, cardnum, cardwidth, digit, 1
        FROM digits INNER JOIN cardranges ON digits.id=cardranges.startid
        UNION ALL
    SELECT startid, endid, cardnum, cardwidth, card_digits || digit, len+1 FROM
        digits_iter INNER JOIN digits ON digits.id=startid+len
        WHERE digits.id<=endid),
cards AS (SELECT startid, endid, cardnum, cardwidth, card_digits FROM digits_iter WHERE len=cardwidth)
SELECT * FROM cards;


-- How could we switch two cards to fix the sequencing error?
-- Find two cards with the same first digit
--   - One card ends with a 4 with 1 on the next card
--   - Another card that ends with a 9 with a 4 on the next card
-- Swap them.
-- There's a parallel version where the change is at the start of a card,
--   but overall "switch two cards and everything else is the same" is
--   vanishingly unlikely compared to the next approach.

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
--   where the group of cards could be moved along

-- Category 1:
-- xxxx9 1x/x4 4xxxx xxxx4 4xxxx 
--         ^--- take one or more adjacent cards
--                        ^--- insert here
-- Pairs 91 44 44 become 94 41 44

-- Category 2:
-- xxxx4 4x/x9 1xxxx xxxx4 4xxxx 
--         ^--- take one or more adjacent cards
--                        ^--- insert here
-- Pairs 44 91 44 becomes 41 44 94

CREATE VIEW sequence_move_one_card AS
WITH pc_50k AS (SELECT * FROM punchcards WHERE endid<=50000),
         my_cards AS (SELECT pc_50k.*,
    SUBSTR(LAG(pc_50k.card_digits) OVER(PARTITION BY pc_50k.cardwidth ORDER BY pc_50k.startid ASC), pc_50k.cardwidth)  AS prev_last,
    SUBSTR(pc_50k.card_digits, 1, 1) AS first,
    SUBSTR(pc_50k.card_digits, pc_50k.cardwidth) AS last,
    SUBSTR(LEAD(pc_50k.card_digits) OVER(PARTITION BY pc_50k.cardwidth ORDER BY pc_50k.startid ASC), pc_50k.cardwidth) AS next_first
    FROM pc_50k),
  candidate_insertpoints AS (SELECT * FROM my_cards WHERE prev_last='4' AND first='4'),
  candidate_sequencing_cat1 AS (SELECT 'cat1' AS category, cardwidth,
                       (prev_last='9' AND first='1') AS is_seq_start, (last='4' AND next_first='4') AS is_seq_end, *
             FROM my_cards WHERE (prev_last='9' AND first='1') OR (last='4' AND next_first='4')),
  candidate_sequencing_cat2 AS (SELECT 'cat2' AS category, cardwidth,
                       (prev_last='4' AND first='4') AS is_seq_start, (last='9' AND next_first='1') AS is_seq_end, *
             FROM my_cards WHERE (prev_last='4' AND first='4') OR (last='9' AND next_first='1')),
  candidate_sequencing AS (SELECT * FROM candidate_sequencing_cat1 UNION ALL SELECT * FROM candidate_sequencing_cat2),
  candidate_sequences AS (SELECT cand_start.category, cand_start.cardwidth, cand_start.cardnum AS seq_start, cand_end.cardnum AS seq_end
         FROM candidate_sequencing cand_start INNER JOIN candidate_sequencing cand_end
        ON cand_start.is_seq_start AND cand_end.is_seq_end AND cand_start.cardnum<=cand_end.cardnum
          AND cand_start.cardwidth=cand_end.cardwidth AND cand_start.category=cand_end.category),
 possible_moves AS (SELECT seq.category, ip.cardwidth, seq_start, seq_end, ip.cardnum AS insert_seq_before, ip.cardnum>seq_end AS ip_is_after
  FROM candidate_sequences seq INNER JOIN candidate_insertpoints ip ON (seq.seq_start=ip.cardnum+1 OR seq.seq_end=ip.cardnum-2)
     AND ip.cardwidth=seq.cardwidth)
SELECT *, CASE WHEN ip_is_after THEN insert_seq_before-1 ELSE insert_seq_before END AS move_card,
       CASE WHEN ip_is_after THEN seq_start ELSE seq_end+1 END AS new_loc
FROM possible_moves
ORDER BY move_card;

