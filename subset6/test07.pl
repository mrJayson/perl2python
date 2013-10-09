#!/usr/bin/perl -w

#simple hash stuff

%d = ("a","b","c","d",1, "1", 2, "2", 3, "3");

print "the variable a is: $d{\"a\"}\n";
$d{"a"} = "B";
print "the variable a is now: $d{\"a\"}\n";
print "the variable 1 is: $d{1}\n";
$d{1} = "11";
print "the variable 1 is now: $d{1}\n";