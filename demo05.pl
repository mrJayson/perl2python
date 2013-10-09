#!/usr/bin/perl -w

#find all primes under n

$n = <STDIN>;
$flag = 0;
for ($i = 2; $n >= $i; $i++) {
	for ($j = 2; $j < $i; $j++) {
		if ($i % $j == 0) {
			$flag = 1;
			last;
		}
	}
	if ($flag == 0) {
		print "$i\n";
	}
	$flag = 0;
}