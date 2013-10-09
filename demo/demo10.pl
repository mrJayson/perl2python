#!/usr/bin/perl -w

#josephus problem

print "How many people in circle?";
$n = <STDIN>;

@list = (1..$n);

print "How many steps per elimination?";
$count = <STDIN>;
$countdown = int($count);
$survivor = 0;

while (@list) {
	if ($countdown > 1) {
		$countdown--;
		$temp = shift(@list);
		push (@list, $temp);
	}
	else {
		$temp = shift(@list);
		$survivor = $temp;
		if ($#list >= 0) {
			print "No.$temp died!\n";
		}
		$countdown = int($count);
	}
}
print "$survivor is the survivor!\n";