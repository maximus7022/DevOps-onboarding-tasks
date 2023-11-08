import time
import re
import sys

def searchWord(word, input_file, output_file):
    with open(input_file, "r") as f:                                        # opening file for reading
        text = f.read()
        pattern = re.compile(r"\b{0}\b".format(word))                       # regex to search only the word
        count = sum(1 for w in re.finditer(pattern, text))                  # word count calculation

        if word in text:
            with open(output_file, "a") as out:                             # opening file for appending
                out.write(f"\n\nFound word '{word}' {count} times at {time.strftime('%Y-%m-%d %H:%M:%S')}:\n")      # writing found words count and search date to file

            with open(input_file, "r") as f:                                # opening file for reading again
                line_num = 1
                for line in f.readlines():                                  # iteration through file lines
                    if re.search(pattern, line):                            # searching pattern matches in each line
                        with open(output_file, "a") as out:                 # opening file for appending again
                            out.write(f"[line {line_num}] --> {line}")      # writing lines with a match to file with specifying line number
                    line_num += 1                                           # counting lines

if __name__ == "__main__":
    searchWord(sys.argv[1], sys.argv[2], sys.argv[3])