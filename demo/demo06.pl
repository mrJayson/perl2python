#!/usr/bin/perl -w

#same as echon.pl

if ($#ARGV == 1+1) {
	$num = $ARGV[0];
	$string = $ARGV[1];
	for ($i = 0; $num > $i; $i++) {
		print "$string\n";
	}
}