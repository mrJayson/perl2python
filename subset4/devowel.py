#!/usr/bin/python2.7 -u
import fileinput, re

for line in fileinput.input():
    line = line.rstrip()
    line = re.sub(r'[aeiou]', '', line)
    print line
