#!/usr/bin/perl -w

$x = 10;

$x++;
$x--;

@array = 0..20;
print shift(@array);
print shift(@array);
print shift(@array);
shift (@array);
push (@array, 10);
pop (@array);
unshift (@array, 10);
for ($i = 0; $i < 4; $i++) {
	print $i;
}
print "\n$x\n";
while (1) {
	print "$x\n";
	if ($x > 10) {
		last;
	}
	$x = $x + 1;
}