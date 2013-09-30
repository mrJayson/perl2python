#!/usr/bin/perl -w


if ($#ARGV+1 != 1) {             #check for correct number of cmd args
   printf ("Usage: %s\n", $0);
   exit 1;
}

#flags for different types of modes
$comment = 0;  
$print   = 0;

#all special chars in perl
$perlsyntax = quotemeta '\\"\'{}()[],$#@<>!=+-*/;';

$file_to_convert = $ARGV[0];

open (F, $file_to_convert) or die "could not open the source file\n";

#array of perl code separated into modular bits
@deconstructed_perl = ();
#converted python will be stored here
@converted_python = ();

#loop through line by line deconstructing the perl code
while ($line = <F>) {
   $line =~ s/([$perlsyntax])([\w]*)/$1 $2/g;
   $line =~ s/([\w]*)([$perlsyntax])/$1 $2/g;
   @line = split(/[ ]+/, $line);    #removes consecutive spaces
   foreach $elt (@line) {
      push (@deconstructed_perl, $elt);
   }
}
#entering different types of modes
while ($#deconstructed_perl >= 0) {
   $elt = shift (@deconstructed_perl);

   if ($elt =~ "#") {
      $comment = 1;                 #enable commenting flag
      &commenting();                #enter commenting mode
   }
   elsif ($elt =~ "print") {
      $print = 1;
      &printing();
   }

   else {
      push (@converted_python, $elt);  #copy direct if don't know how to handle
   }

}

#print converted python code
&printArray(@converted_python);

sub printArray () {
   my (@array) = @_;

   foreach $elt (@array) {
      print "$elt\n";
   }
}

#commenting mode
sub commenting () {
   my $commentString = '#';                  #all comments start with #
   while ($#deconstructed_perl >= 0) {
      $elt = shift (@deconstructed_perl);
      if ($elt =~ /^\n$/) {                  #check if comment finished
         if ($commentString =~ "perl-w") {
            $commentString =~ s/perl-w/python2.7 -u/;
         }
         push (@converted_python, $commentString);
         $comment = 0;                       #disable commenting flag
         last;
      }
      $commentString .= $elt;                #copy everything literally since they're comments
   }
}

#printing mode
sub printing () {
   my $printString = 'print';                #all printing starts with print
   my $openString = 0;                       #flag for literal strings
   my $openBracket = 0;                      #added so that brackets are included
   while ($#deconstructed_perl >= 0) {
      $elt = shift (@deconstructed_perl);
      if ($elt =~ /\(/) {
         $openBracket = 1;
         $printString .= $elt;
      }
      elsif ($elt =~ "\"") {
         if ($openString == 0) {
            if ($openBracket == 0) {         #if open quotes before bracket, add in bracket
               $openBracket = 1;
               $printString .= "(";
            }
            $openString = 1;
            $printString .= $elt;
         }
         elsif ($openString == 1) {
            $openString = 0;
            chop ($printString) if ($printString != "print (");# chop is used if there was a word only
            $printString .= $elt;

         }
      }
      elsif ($elt =~ /\\/ && $openString == 1) {   #for \ flags during openString mode
         $elt = shift (@deconstructed_perl);
         if ($elt =~ "n") {
            
         }
      }
      
      elsif ($openString == 1) {                   #default literal copying of string
         $printString .= $elt." ";
      }
      else {                                       #for everything else when string is closed
         if ($elt =~ /\)/) {
            $openBracket = 0;
            $printString .= $elt;
         }
         elsif ($elt =~ ";") {                     #all perl code ends with ;
            if ($openBracket == 1) {
               $printString .= ")";
            }
            push (@converted_python, $printString);
         }
      }
   }
}
