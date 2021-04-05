-- Queries used to answer questions in the Aug 2020 MW briefing

-- All the tables with differences are in views beginning with "check_"

-- Which rows reference themselves as the first few digits:
INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('row_contains_self', 'Rows containing a reference to themselves',
   'Every row in the book is numbered; look for rows that contain themselves');

CREATE VIEW IF NOT EXISTS row_contains_self AS
SELECT rownum, page,
       (SUBSTR(rowtext, 1, LENGTH(rownum))=rownum) AS startswith,
       (SUBSTR(rowtext, LENGTH(rowtext)-LENGTH(rownum)+1)=rownum) AS endswith,
       0<INSTR(rowtext, CAST(rownum AS TEXT)) AS contains,
       orig_rowtext
       FROM digits_row
  WHERE 0<INSTR(rowtext, CAST(rownum AS INTEGER))
  ORDER BY startswith DESC, endswith DESC, LENGTH(rownum) DESC;

-- Looking for biases in the row selection part of the selection algorithm
INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('random_selection_algorithm_rows', 'Original algorithm to select rows',
   'The book describes an algorithm to select the random number to choose. ' ||
   'Run that algorithm and count the number of times each row might be chosen');

CREATE VIEW IF NOT EXISTS random_selection_algorithm_rows AS
WITH rowselect AS (SELECT rownum, val,
    CAST((CAST(SUBSTR(t, 1, 1) AS INTEGER)%2) || SUBSTR(t, 2) AS INTEGER) AS newrow FROM digits_tuples)
SELECT dt.rownum, COUNT(rowselect.rownum) AS n_times_selected
  FROM digits_tuples dt LEFT JOIN rowselect ON rowselect.newrow=dt.rownum
  WHERE dt.rownum IS NULL OR dt.colnum=0
   GROUP BY dt.rownum
  ORDER BY COUNT(rowselect.rownum)>0, COUNT(rowselect.rownum) ASC;


-- Looking for biases in the digits chosen by the selection algorithm
INSERT OR IGNORE INTO view_description (view_name, long_name, description) VALUES
  ('random_selection_algorithm_digits', 'Original algorithm to select digits',
   'The book describes an algorithm to select the random number to choose. ' ||
   'Run that algorithm and count the number of times each digit might be chosen');

CREATE VIEW IF NOT EXISTS random_selection_algorithm_digits AS
WITH rowselect AS (SELECT rownum, colnum, val,
           CAST((CAST(SUBSTR(t, 1, 1) AS INTEGER)%2) || SUBSTR(t, 2) AS INTEGER) AS newrow FROM digits_tuples),
    nexttwo AS (SELECT dt.*, SUBSTR(dt2.t, 1, 2)%50 AS newcol
       FROM digits_tuples dt INNER JOIN digits_tuples dt2 ON
           dt2.rownum=dt.rownum+CAST(dt.colnum=9 AS INTEGER) AND dt2.colnum=(dt.colnum+1)%9),
  selectedrows(newrow) AS (SELECT DISTINCT newrow FROM rowselect),
    randomdigit AS (SELECT rowselect.rownum, rowselect.colnum, rowselect.val, rowselect.newrow, nexttwo.newcol, digits_row.rowtext,
         SUBSTR(digits_row.rowtext, (nexttwo.newcol+1), 1) AS chosendigit
       FROM rowselect INNER JOIN nexttwo ON rowselect.rownum=nexttwo.rownum AND rowselect.colnum=nexttwo.colnum
  INNER JOIN digits_row ON rowselect.newrow=digits_row.rownum)
 SELECT chosendigit, COUNT(*) AS n_times_selected,
        ROUND(100*CAST(COUNT(*) AS REAL)/(SUM(COUNT(*)) OVER ()), 3) AS prob_chosen
    FROM randomdigit GROUP BY chosendigit;

