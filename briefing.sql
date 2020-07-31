-- Queries used to answer questions in the Aug 2020 MW briefing

-- All the tables with differences are in views beginning with "check_"

-- Which rows reference themselves as the first few digits:
SELECT * FROM digits_row WHERE SUBSTR(rowtext, 1, LENGTH(rownum))=rownum;

-- Looking for biases in the row selection part of the selection algorithm
WITH rowselect AS (SELECT rownum, val, CAST((CAST(SUBSTR(t, 1, 1) AS INTEGER)%2) || SUBSTR(t, 2) AS INTEGER) AS newrow FROM digits_tuples)
SELECT dt.rownum, COUNT(rowselect.rownum) AS n_selected
  FROM digits_tuples dt LEFT JOIN rowselect ON rowselect.newrow=dt.rownum
  WHERE dt.rownum IS NULL OR dt.colnum=0
   GROUP BY dt.rownum
  ORDER BY COUNT(rowselect.rownum)>0, COUNT(rowselect.rownum) DESC;


-- Looking for biases in the digits chosen by the selection algorithm
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
 SELECT chosendigit, COUNT(*), ROUND(100*CAST(COUNT(*) AS REAL)/(SUM(COUNT(*)) OVER ()), 3) FROM randomdigit GROUP BY chosendigit;


-- Looking for existence of runs on boundaries between cards
SELECT L.cardwidth, L.end_len+R.start_len AS boundarylen, COUNT(*) AS cnt
   FROM punchcard_endruns L INNER JOIN punchcard_endruns R
    ON L.cardwidth=R.cardwidth AND L.end_digit=R.start_digit AND L.cardnum!=R.cardnum
      AND L.end_len+R.start_len BETWEEN 3 AND 7
  GROUP BY L.cardwidth, boundarylen;

