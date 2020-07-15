# Automatic Digit Extraction

## What?

From the PDF on RAND's website of the million digits, this folder contains
a couple scripts that will take that PDF, and create a folder structure
of images; there's a folder for each digit 0-9, and each image file is
named after its (0-offset) index into the million.

## Why?

I wanted to extract all the digits so I could do an MNIST-style training
exercise, and look for a single two labeled as a zero, between digits
350,000 and 400,000

## What does this tower of cards need?

This makes excessive use of imagemagick and uses pdftoppm for initial
PDF extraction.

The python code needs numpy and sklearn.

## How do I use it?

```sh conv.sh```

## And? Did you succeed?

No. Every digit I have labeled as a zero looks like a beautifully
round picture of a zero.