#!/usr/bin/perl -w

@files = ();
$N = 10;

foreach $arg (@ARGV) {
	push (@files, $arg);
}

foreach $f (@files) {
	open(F,"<$f");
	while ($line = <F>) {
		print "$line";
	}
}