#!/usr/bin/perl -w

#tail.pl

@files = ();
$N = 10;

foreach $arg (@ARGV) {
	push (@files, $arg);
}

foreach $f (@files) {
	@text = ();
	open(F,"<$f");
	print "==> $f <==\n";
	while ($line = <F>) {
		push (@text, $line);
	}
	for ($i = 0; $i < $#text+1; $i++) {
		if ($i >= $#text + 1 - $N) {
			print $text[$i];
		}
	}
}