
@array = ("h","e","l","l","o");

for ($q = 0; $q < 10; $q = $q + 1) {
	for ($w = 0; $w < 10; $w = $w + 1) {
		print "inner $w\n";
	}
	print "outer $q\n";
}

for $i (@array) {
	print "foreach $i\n";
}