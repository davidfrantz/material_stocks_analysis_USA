#!/usr/bin/env python3

import os
import sys
import pandas as pd
import numpy as np
import csv

print('Number of arguments:', len(sys.argv), 'arguments.')
print('Argument List:', str(sys.argv))

outPath = str(sys.argv[1]).split(" ")[0]

sums = []
for i in range(2,len(sys.argv)):
    df = pd.read_csv(sys.argv[i], sep=";")
    sums.append(df)
  
frame = pd.concat(sums, axis=0, ignore_index = True)
frame.columns = ["zone","sum"]
groupedDF = frame.groupby("zone").sum()
groupedDF.to_csv(outPath, sep=";", header=True, quoting = csv.QUOTE_NONE)
