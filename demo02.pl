#!/usr/bin/perl -w

#finding factors

$n = 360;
@factors = ();

for ($i = 1; $i <= $n; $i++) {
	if ($n % $i == 0) {
		push (@factors, $i);
	}
}
foreach $a (@factors) {
	print "$a\n";
}