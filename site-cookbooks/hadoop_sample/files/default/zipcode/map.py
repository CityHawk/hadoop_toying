#!/usr/bin/env python
import sys
for lineIn in sys.stdin:
    zip = lineIn[1:6]
    #       Note: Key is defined here
    if not zip=='zip",':
        sys.stdout.write(zip + '\t' + lineIn)
