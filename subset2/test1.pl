#!/usr/bin/perl -w


$number = 0;

if ($number == 0) {
	print "this is 0!\n";
	$number = $number + 1;
}

if ($number == 0) {
	print "this is still 0!\n";
}
elsif ($number == 1) {
	$number = $number - 1;
}

while ($number < 10) {
	$number = $number + 1;
}