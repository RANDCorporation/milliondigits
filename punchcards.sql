-- The digits were originally on punchcards.
-- What would this look like on its original punchcards?


CREATE TABLE IF NOT EXISTS punchcard_widths (width INTEGER NOT NULL, description TEXT NOT NULL, UNIQUE(width));
CREATE TABLE IF NOT EXISTS punchcard_ranges (cardwidth INTEGER NOT NULL REFERENCES punchcard_widths(width),
	 startid INTEGER NOT NULL, endid INTEGER NOT NULL, cardnum INTEGER NOT NULL,
	 UNIQUE(cardwidth, startid, endid));
CREATE INDEX IF NOT EXISTS idx_punchcard_ranges_sw ON punchcard_ranges(startid, cardwidth);
CREATE TRIGGER IF NOT EXISTS trig_create_cards AFTER INSERT ON punchcard_widths FOR EACH ROW BEGIN
  DELETE FROM punchcard_ranges WHERE cardwidth=NEW.width;
  INSERT INTO punchcard_ranges (startid, endid, cardnum, cardwidth) SELECT min(id), max(id), (id-1)/NEW.width, NEW.width
     FROM digits GROUP BY NEW.width, (id-1)/NEW.width;
END;

-- https://en.wikipedia.org/wiki/Punched_card#Card_formats
-- Only include likely candidates for the million original digits
INSERT INTO punchcard_widths (width, description) VALUES
 -- (40, 'IBM Port-a-Punch'),
 (80, 'Standard IBM card'),
 (72, 'FORTRAN')
 -- (90, 'Remington Rand Double 45'),
 -- (96, 'IBM 96-column [post-1955]'),
 -- (160, 'Double-coded Standard IBM card'),
 -- (144, 'Double-coded FORTRAN')
;

ANALYZE;

CREATE VIEW IF NOT EXISTS punchcards AS
WITH RECURSIVE digits_iter(startid, endid, cardnum, cardwidth, card_digits, len) AS
    (SELECT startid, endid, cardnum, cardwidth, digit, 1
        FROM digits INNER JOIN punchcard_ranges ON digits.id=punchcard_ranges.startid
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
    WHERE digits.id<=50000)
SELECT * FROM reordered_digits
    ORDER BY cardwidth, take_card, insert_before, new_digit_id;


