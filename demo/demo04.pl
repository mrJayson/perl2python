 #!/usr/bin/perl -w
 
#selection sort

@list = (3,4,6,2,8,1,2,5,8,4);

while (@list) {
	$lowest = shift(@list);
	foreach $i (@list) {
		$compare = shift(@list);
		if ($lowest > $compare) {
			push (@list, $lowest);
			$lowest = $compare;
		}
		else {
			push (@list, $compare);
		}
	}
	print "$lowest\n";
}
