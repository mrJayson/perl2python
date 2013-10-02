
@array = ("h","e","y","o");

for ($q = 0; $q < 10; $q = $q + 1) {
	print "C style $q\n";
}

for $i (@array) {
	print "foreach $i\n";
}