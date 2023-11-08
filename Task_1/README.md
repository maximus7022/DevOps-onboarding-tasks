# Word Search Script Documentation

## Overview

This documentation outlines two methods to solve the task of searching for a specific word in a text file every 15 minutes and writing the results to a different file. The two methods are implemented using a Bash script and a Python script, both scheduled to run at 15-minute intervals through a crontab entry.

## Method 1: Bash Script

### Script Description

The Bash script is responsible for searching a specified word in an input file and recording the results in an output file. It leverages commonly available Unix utilities like `grep` to perform the word search. The script takes three arguments:

1. `$1`: The word to search.
2. `$2`: The input file in which to search.
3. `$3`: The output file to write the search results.

### Script Implementation

```bash
#!/bin/sh

echo "Found $(grep -i -o -w $1 $2 | wc -l) entries of '$1' at $(date):" >> $3
echo "$(grep -i $1 $2)\n" >> $3
```

- The script first executes `grep` with options to search for the word case-insensitively, matching whole words only.
- It counts the occurrences of the word using `wc -l`.
- The script appends a timestamp and the search results to the output file.

### Crontab Entry

The Bash script is scheduled to run every 15 minutes in the crontab:

```bash
*/15 * * * * /path/to/script.sh word_to_search input_file output_file
```

## Method 2: Python Script

### Script Description

The Python script also searches for a specified word in an input file and records the results in an output file. It provides more flexibility and control over the search process. The script uses regular expressions to match the word and counts its occurrences. The script takes three command-line arguments:

1. `word`: The word to search.
2. `input_file`: The input file in which to search.
3. `output_file`: The output file to write the search results.

### Script Implementation

```python
import time
import re
import sys

def searchWord(word, input_file, output_file):
    with open(input_file, "r") as f:
        text = f.read()
        pattern = re.compile(r"\b{0}\b".format(word))
        count = sum(1 for w in re.finditer(pattern, text))

        if word in text:
            with open(output_file, "a") as out:
                out.write(f"\n\nFound word '{word}' {count} times at {time.strftime('%Y-%m-%d %H:%M:%S')}:\n")

            with open(input_file, "r") as f:
                line_num = 1
                for line in f.readlines():
                    if re.search(pattern, line):
                        with open(output_file, "a") as out:
                            out.write(f"[line {line_num}] --> {line}")
                    line_num += 1

if __name__ == "__main__":
    searchWord(sys.argv[1], sys.argv[2], sys.argv[3])
```

- The script reads the input file, searches for the word using regular expressions, and counts the occurrences.
- It appends the search results, including the word count and timestamp, to the output file, and also specifies the line number of matches.

### Crontab Entry

The Python script is scheduled to run every 15 minutes in the crontab:

```bash
*/15 * * * * /usr/local/bin/python3 /path/to/script.py word_to_search input_file output_file
```

## Conclusion

Both methods provide solutions to the task of searching for a word in a file at 15-minute intervals and writing the results to a different file. The choice between Bash and Python depends on your preferences and specific requirements. You can use the provided crontab entries to automate the process based on your needs.