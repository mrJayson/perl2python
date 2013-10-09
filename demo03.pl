#!/usr/bin/perl -w

#piglatin translator!

while ($line = <>) {
	$line =~ s/(\w)(\w+)/$2$1ay/;	#handles for capture groups
	print "$line\n";
}