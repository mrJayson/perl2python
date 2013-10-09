#!/usr/bin/perl -w

#palindrome checker

$line = <STDIN>;
chomp ($line);

$rev_line = $line;
$rev_line = reverse ($rev_line);

if ($line eq $rev_line) {
	print "$line is a palindromic! :D\n";
}
else {
	print "$line is not palindromic :(\n";
}