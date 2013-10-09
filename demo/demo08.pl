#!/usr/bin/perl -w

#fibonnaci sequence

$n = <STDIN>;

$fibo = 1;
$fiboPrev = 1;
if ($n >= 2) {
	print "1\n";
}
if ($n >= 1) {
	print "1\n";
}
for ($i = 2; $n > $i; $i++) {
    $temp = $fibo;
    $fibo = $fibo + $fiboPrev;
    $fiboPrev = $temp;
    print "$fibo\n";
}
