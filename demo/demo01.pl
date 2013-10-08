#!/usr/bin/perl -w

#collatz conjecture
$n = 387;
while ($n > 1) {
	if ($n % 2 == 1) {
		$n = $n * 3 + 1;
	} else {
		$n = $n / 2;
	}
	print "$n\n";
}