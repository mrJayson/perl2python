#!/usr/bin/python2.7 -u
import sys

while 1:
    print "Give me cookie"
    line = sys.stdin.readline()
    line = line.rstrip()
    if line == "cookie":
        break
print "Thank you"
