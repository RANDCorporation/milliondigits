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
CREATE VIEW switch_cards_sequencing AS
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


