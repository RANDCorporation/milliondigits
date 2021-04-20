# A Million Random Digits with 100,000 Normal Deviates

## Introduction

To keep my SQL skills sharp during early 2020 lockdown, I tried to
reproduce the work of [RAND](https://www.rand.org)'s seminal 1955 paper,
*"A Million Random Digits with 100,000 Normal Deviates"*.

I failed. Not to recreate the same analysis; but to completely reproduce
the precise same results. The differences are inconsequential, the digits
are just as random, and useful, as they were originally; but the data on
RAND's public website does not generate precisely the same results as that
in the paper.

## Differences

* In Table 1, *"Frequencies of One Million Digits"*, I find one additional 
   zero and one fewer two, somewhere between digits 350,000 and 400,000
* In Table 3, *"Poker Tests on The Million Digits"*, I find one additional
  *Bust*, four additional *Pair*, four fewer *Two pairs*, and one fewer
  *Full house*
* In Table 5, *"Frequencies of Ordered Pairs of Digits"*, I find one
  additional 4,4, one additional 9,1, and one fewer 9,4 and one fewer 4,1
* In Table 6, *"Run Test"*, I find 31 additional singles, two additional 
  pairs, 1 fewer run of 3, and eight fewer runs of four

## Hypotheses

I hypothesise a number of ways these differences could come about.

### Error in this code, or original code

Given that these results are "incredibly close", it seems unlikely.
Unfortuantely, the original code is lost to time.

### Transcription Problem

The digits were originally created on 20,000 punchcards. Those went
through various iterations and interpretations before ending up on
RAND's website as a digital file. One of the differences identified
could be literally a single bit-flip, which feels "possible".

### Punchcard Esoterica

I could find no literature on the subject of punchard machines and error
rates. Perhaps a hanging chad or dimpled chat?

Famously, punchcards would occasionally get dropped and a poor tech
would have to spend all night reordering them. Much of the code in this
repository explores the possibility of a deck being out of order. I do
not find any "smoking gun" cases (a simple re-ordering that would
simultaneously explain all the differences), but a number of candidate
reorderings that can explain each individual difference.

### Changes over time

The originalmost paper was missing a digit in print. Various other
iterations and editions have occurred over time; it's possible that
these differences appear later.

## Other explorations and tests

The "ocr" folder includes scripts necessary to extract images from PDFs
of the original paper on RAND's website, for running through a simple
AI/image recognition tool. The digits handled this way do seem to align
with that in the digital file.

I estimated it would cost ~3k USD to human-OCR this with Mechanical Turk.

"MDSearch" is a simple Java GUI for automatically populating the search
table and querying it.

## Conclusions

* None of these differences are statistically significant,
* I do believe the original tests accurately measured the data on the 
  punchcards, and
* If you follow the original instructions, you still get high-quality 
  randomness.

## References

Data, as well as original analysis, sourced from this page:
https://www.rand.org/pubs/monograph_reports/MR1418.html

WSJ Article: https://www.wsj.com/articles/rand-million-random-digits-numbers-book-error-11600893049

## Database Notes

The database I use is sqlite3, version 3.31 or later. I use a trigger
on a temporary view to do the initial load (which isn't very portable
to other databases); I expect the rest of the code to mostly work on at
least PostgreSQL, but haven't tested it.

Tables prefixed with "mr1418_" are the results from the analysis in
the original paper. Views with a "check_" prefix compare results from
the original work with reproduced results.

A great deal of my explorations are looking for possible punchcards
out of order to cause the differences I see. I find candidate possibilities,
but not anything convincing or conclusive on the subject.

## Some examples

Use recreate.sh to recreate the database. Some examples of queries:

```sql
$ sqlite3 -header -column -init import.sql

> SELECT digit, COUNT(*) AS freq,
   SUM(COUNT(*)) OVER (ORDER BY digit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_freq
   FROM digits GROUP BY digit ORDER BY digit;

digit  freq    cum_freq
-----  ------  --------
0      99803   99803   
1      100050  199853  
2      100640  300493  
3      100311  400804  
4      100094  500898  
5      100214  601112  
6      99942   701054  
7      99559   800613  
8      100107  900720  
9      99280   1000000   

> SELECT AVG(digit) FROM digits;
AVG(digit)
----------
4.49465

> SELECT MIN(val), AVG(val), MAX(val), SUM(val) FROM deviates;
MIN(val)    AVG(val)              MAX(val)    SUM(val)
----------  --------------------  ----------  -----------------
-4.417      -0.00342697999999514  3.976       -342.697999999514

> -- RAND Office Phone Numbers
> INSERT OR IGNORE INTO searchvals VALUES ('3930411'), ('4131100'), ('6832300');
> SELECT q, page, rownum, orig_rowtext FROM dosearch WHERE found;
q           page        rownum      orig_rowtext                                                   
----------  ----------  ----------  ---------------------------------------------------------------
4131100     293         14614       41069 15749  28541 31100  25983 21706  09643 07666  01573 52145

> .mode list
> SELECT * FROM deviates_hist ORDER BY CAST(x AS REAL) ASC;
-4.5|.|           4
-4.3|.|           1
-4.1|.|           2
-3.9|.|           2
-3.7|.|           9
-3.5|.|           16
-3.3|.|           31
-3.1|.|           72
-2.9|#|           111
-2.7|##|           211
-2.5|###|           343
-2.3|#####|           509
-2.1|########|           822
-1.9|#############|           1296
-1.7|##################|           1841
-1.5|#########################|           2535
-1.3|##################################|           3415
-1.1|###########################################|           4323
-0.9|####################################################|           5187
-0.7|##############################################################|           6182
-0.5|#######################################################################|           7049
-0.3|##############################################################################|           7728
-0.1|##############################################################################|           7805
 0.1|################################################################################|           7905
 0.3|##############################################################################|           7738
 0.5|########################################################################|           7155
 0.7|###############################################################|           6321
 0.9|#####################################################|           5264
 1.1|############################################|           4408
 1.3|##################################|           3428
 1.5|##########################|           2654
 1.7|###################|           1936
 1.9|#############|           1337
 2.1|#########|           915
 2.3|#####|           577
 2.5|###|           362
 2.7|##|           227
 2.9|#|           149
 3.1|.|           57
 3.3|.|           35
 3.5|.|           27
 3.7|.|           6
 3.9|.|           6
 4.1|.|           1
 4.3|.|           1
```

## License

This code is Copyright (C) 2021 RAND Corporation, and provided under the MIT license

Gary  
<gbriggs@rand.org>
