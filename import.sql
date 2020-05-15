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
CREATE UNIQUE INDEX idx_digits ON digits(rownum, colnum, colidx);
CREATE INDEX idx_digits_t ON digits(t);
CREATE INDEX idx_digits_digit ON digits(digit);

CREATE UNIQUE INDEX idx_deviates_row ON deviates_row(rownum);
CREATE UNIQUE INDEX idx_deviates ON deviates(rownum, colnum);
CREATE INDEX idx_deviates_val ON deviates(val);

ANALYZE;


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
  SELECT found, q, t_sofar, startid, ROW_NUMBER() OVER (PARTITION BY startid, q ORDER BY DEPTH desc) AS matchrank, depth AS matchlen, rownum, page, orig_rowtext
    FROM search INNER JOIN digits_row ON digits_row.rownum=search.startrownum)
  WHERE matchrank=1 
  ORDER BY matchlen DESC;

CREATE VIEW IF NOT EXISTS deviates_hist AS
WITH createbar(b) AS (SELECT '#' UNION ALL SELECT b || '#' FROM createbar WHERE LENGTH(b)<500),
 bar(b) AS (SELECT b FROM createbar ORDER BY LENGTH(b) DESC LIMIT 1),
 buckets(b_min, b_max, delta) AS (SELECT MIN(val)-0.0001, MIN(val)+0.2, 0.2 FROM deviates
   UNION ALL SELECT b_min+delta, b_max+delta, delta FROM buckets WHERE b_max<=(SELECT MAX(val) FROM deviates))
SELECT SUBSTR('   ' || ROUND((b_min+b_max)/2.0, 1), -4) AS x,
   CASE WHEN COUNT(*)=0 THEN ' ' WHEN COUNT(*)<50 THEN '.' ELSE SUBSTR(b, 1, COUNT(*)/50) END AS bar
   FROM bar, buckets LEFT JOIN deviates ON deviates.val<=buckets.b_max AND deviates.val>buckets.b_min
   GROUP BY buckets.b_min ORDER BY val;

