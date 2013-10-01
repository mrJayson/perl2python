#!/usr/bin/perl -w

@import_python_libs = ();

@python_code = ();
#run through each line and transform $line to python as it goes
while ($line = <>) {
   #account for different scenarios in perl
   if ($line =~ "#!/usr/bin/perl -w") {
      $python_line = "#!/usr/bin/python2.7 -u\n";
   }
   elsif ($line =~ /^\s*print.*/) {
      $python_line = &_print($line);
   
   }
   elsif ($line =~ /^\s*(my)?\s*\$\S+\s*=/) {
      $python_line = &_variable_dec($line);
   }
   else {
      $python_line = "#" . $line;
   }
   #push converted python into array
   push (@python_code, $python_line);

}
&insert_libs(@import_python_libs);
print @python_code;

sub _variable_dec() {
   my ($line) = @_;
   my $python_line = '';
   $line =~ s/\$//g;
   $python_line = $line . "\n";
   return $python_line;
}

sub _print() {
   my $variable_search_regex = qr/\$[^\W]+(?:\s*(?:\*|\+|\/|-|\*\*|%)\s*\$[^\W]+)*/;    #store the regex to collect variables from a string
   my ($line) = @_;
   my $python_line = "";
   $line =~ s/\\n";\s*$/";/;              #removes the ending newline in perl's version
   my @regex_matches = ($line =~ /(".*?"|$variable_search_regex)/g);  
   #match for each subsection of print string, basically removes all concats

   my @var_formatting = ();
   foreach my $match (@regex_matches) {
      $python_line .= $match;             #concat all substrings into one
      $python_line =~ s/([^\\]|^)"/$1/g;  #removes all quote char
      $python_line =~ s/([^\\]|^)"/$1/g;  #removes all quote char, run twice because can't use lookbehind
      #all print strings are now one long string without concats
   }
   #print $python_line."\n";
   $python_line = "\"" . $python_line . "\"";      #adds quotes to the begin and end of whole string
   @var_formatting = ($python_line =~ /($variable_search_regex)/g); #collect variables for new formatting
   my $i = 0;                                      #counter variable
   $python_line =~ s/($variable_search_regex)/"{".$i++."}"/eg;     #adds formatting to the string
   $python_line .= ".format(";                     #adds the format to variables
      foreach my $var (@var_formatting) {
         $var =~ s/\$//g;
         $python_line .= "$var,";                  #adding in var at a time
      }
      $python_line =~ s/,$//;                      #chomp off the last ","
   $python_line .= ")";                            #close off the format parentheses
   return "print " . $python_line . "\n";          #add finishing touches to print line
}

sub insert_libs() {
   my (@libs) = @_;
   foreach $lib (@libs) {
      splice (@python_code, 1, 0, "import $lib\n");
   }
}

#add libraries to python if not added yet
sub add_lib() {
   my ($library) = @_;  #input library
   my $seen = 0;
   #loop through each lib in list so far
   foreach $import (@import_python_libs) {
      if ($import eq $library) {
         $seen = 1;
         last;
      }
   }
   if ($seen == 0) {
      push (@import_python_libs, $library);
   }
}
