#!/bin/sh

echo "Found $(grep -i -o -w $1 $2 | wc -l) entries of '$1' at $(date):" >> $3
echo "$(grep -i $1 $2)\n" >> $3

# $1 = word to search
# $2 = input file to search in
# $3 = output file to write result in