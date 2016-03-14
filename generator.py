import random
import sys

ROWS = 1080
COLUMNS = 1920
MATRIX_EIGHT_BIT = 255
INTEGER = 750
NEW_FILE = 'gettingMatrixVal.txt'

def getRandMatrix (row, column):
  random_matrix = []

  for rows in range (0, row):
    for columns in range (0, column):
      random_matrix.append(random.randint(0, MATRIX_EIGHT_BIT))
  return random_matrix

matrixA = getRandMatrix(ROWS, COLUMNS)
matrixB = getRandMatrix(COLUMNS, INTEGER)


this_file = open(NEW_FILE, 'w')

for position, random_matrix in enumerate([matrixA, matrixB]):
  if position != 0:
    this_file.write("\n")
  for this_pos in random_matrix:
    this_file.write(str(this_pos) + "\n")
    
this_file.close()


