# Million Digits Search

## Introduction

My original goal with this effort was, depending on your view, either

1. something inherently intellectually corrupt, or
1. a silly party trick that no-one but me would think funny

I wanted to be able to search through the million digits for a chosen
number; for use as a chosen random seed in a model / my name / the
moon landing / whatever. Then be able to "randomly" flip open to an
invisibly-bookmarked page while someone is in the room, and get the
number I want - eg to get a pre-chosen model result, but at "random".

The view "dosearch" in the database created will do this; insert a
search string into the "searchvals" table, then select from dosearch.

I found manually running the SQL to search for all the things I might
try was taking a long time. So I put together a tool to automatically
search for stuff, in real-time as I typed. It also automatically converts
characters to various encodings, recognises ISO dates and searches on a
bunch of standard date formats, etc.

## Building and Running

This is developed using Netbeans, mainly for the GUI builder, but netbeans
isn't required to build it. Build the database in the folder above this
one (recreate.sh will do it for you), then manually copy it to this folder.  

You can compile and execute using maven:
```shell
mvn compile exec:java
```

Or use the shellscript ```build.sh``` to a build and package a complete
zipfile that contains everything needed to run (except Java itself). 

Cheers,  
Gary  
<gbriggs@rand.org>