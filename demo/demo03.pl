#!/usr/bin/perl -w

#piglatin translator!

while ($line = <>) {
	$line =~ s/(\w)(\w+)/$2$1ay/;
	print "$line\n";
}