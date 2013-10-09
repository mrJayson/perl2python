#!/usr/bin/perl -w

@array = (1,2,3,4,5,6,7,8,9,10);

$total = 0;

while (@array) {
	$elt = shift(@array);
	$total = $total + $elt;
}
print "total: $total\n";