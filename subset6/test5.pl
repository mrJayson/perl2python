
@array = ("h","e","y","o");

for ($q = 0; $q < 10; $q = $q + 1) {
	for ($w = 0; $w < 10; $w = $w + 1) {
		print "Super C style $w\n";
	}
	print "C style $q\n";
}

for $i (@array) {
	print "foreach $i\n";
}