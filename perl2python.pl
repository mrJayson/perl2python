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
      &add_lib("sys");
   
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
   $line =~ s/^\s*my\s*\$//;
   $line =~ s/^\s*\$//;    #need to make it handle for global vars
   $line =~ s/;\s*$//;
   $python_line = $line . "\n";
   return $python_line;
}

sub _print() {
   my ($line) = @_;
   chomp ($line);
   $line =~ s/\s*print\s*\(?//i;
   my $python_line = "print ";
   $line =~ s/;\s*$//;# removes the semicolon
   $line =~ s/("[^"]*"|\$\w+)\s*\.\s*("[^"]*"|\$\w+)/$1 + $2/g; #replace all dots for perl concat to + for python concat
   $line =~ s/("[^"]*"|\$\w+)\s*\.\s*("[^"]*"|\$\w+)/$1 + $2/g; #run regex twice because it still misses some
   $line =~ s/\$(\S+)/$1/g;#removes all dollar signs from perl's variables
   $line =~ s/\\n"\s*$/"/;
   $python_line .= $line . "\n";#add the ending for print
   return $python_line;
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
