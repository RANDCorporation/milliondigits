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
 (50, 'Apparent real source'),
 (80, 'Standard IBM card'),
 -- (74, 'Not quite 75'),
 -- (76, 'Seventy Six'),
 -- (73, 'Seventy Three'),
 (72, 'FORTRAN')
 -- (92, 'Ninety Two'),
 -- (90, 'Remington Rand Double 45'),
 -- (96, 'IBM 96-column [post-1955]')
 -- (160, 'Double-coded Standard IBM card'),
 -- (144, 'Double-coded FORTRAN')
;

ANALYZE;

INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('punchcards', 'Simulated Punchcards',
   'For each possible punchcard width, simulate what all the punchcards would have looked like');

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

