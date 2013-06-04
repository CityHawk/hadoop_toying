#!/usr/bin/env python
import sys
for lineIn in sys.stdin:
       zip = lineIn[0:5]
#       Note: Key is defined here
       print zip + '\t' + lineIn
