-- A simple example to search the database for a particular string
--   of digits, ignoring spaces, newlines, etc

WITH RECURSIVE q(q) AS (SELECT '4740763'),
  search AS (SELECT q.q AS q, id AS startid, digits.rownum AS startrownum, 1 AS depth, id AS lastid, digits.t AS t_sofar, 0 AS found
    FROM digits,q WHERE SUBSTR(q.q, 1, 1)=digits.t
 UNION ALL
     SELECT q, startid, startrownum, depth+1, digits.id, search.t_sofar || digits.t, depth+1=LENGTH(q) AS found
    FROM search INNER JOIN digits ON digits.id=search.lastid+1
         WHERE SUBSTR(search.q, depth+1, 1)=digits.t
   )
SELECT * FROM (
  SELECT found, q, t_sofar, startid, ROW_NUMBER() OVER (PARTITION BY startid, q ORDER BY DEPTH desc) AS matchrank,
      depth AS matchlen, rownum, page, orig_rowtext
    FROM search INNER JOIN digits_row ON digits_row.rownum=search.startrownum)
  WHERE matchrank=1
  ORDER BY matchlen DESC LIMIT 20;

