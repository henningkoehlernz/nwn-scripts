# format 2DA file for readability
import sys

# read input
raw2da = [ line.split() for line in sys.stdin ]
# push 3rd line entry (header) back one column
raw2da[2].insert(0, "")
# find max number of columns
column_count = max( len(row) for row in raw2da )
# find max width of each column
column_max_width = [ max( len(row[col] ) for row in raw2da if len(row) > col ) for col in range(column_count) ]
# set target width to smallest value = 1 mod tab-width
TAB_WIDTH = 4
column_width = [ width + (TAB_WIDTH - 1 - width % TAB_WIDTH) for width in column_max_width ]
# extend 2da entries to match width
formatted2da = [ [ row[col].ljust(column_width[col]) for col, value in enumerate(row) ] for row in raw2da ]
# un-format first row (version number)
formatted2da[0] = raw2da[0]
# print
for row in formatted2da:
    print(" ".join(row).rstrip())
