#!/usr/bin/perl -w

@import_python_libs = ();

@python_code = ();
$tab_indent = 0;
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
   elsif ($line =~ /^\s*(?:if|while)/) {
      $python_line = &_if_or_while_statement($line);
      $tab_indent++;       #translate the if statement first, then increment the tab count
   }
   elsif ($line =~ /^\s*\}\s*$/) {
      $tab_indent--;
      $python_line = "";
   }
   else {
      $python_line = "#" . $line;
   }
   #push converted python into array
   push (@python_code, $python_line);

}
&insert_libs(@import_python_libs);
print @python_code;

sub _if_or_while_statement() {
   my ($line) = @_;
   chomp ($line);
   my $python_line = &_insert_indentation();
   $line =~ s/(if|while)\s*\((.*?)\)\s*\{/$2/;
   $python_line .= "$1 " . &_conditions($line) . ":\n";
   return $python_line;
}

sub _variable_dec() {
   my ($line) = @_;
   my $python_line = &_insert_indentation();
   $line =~ s/^\s*//g;
   $line =~ s/\$//g;
   $line =~ s/;\s*$//;
   $python_line .= $line . "\n";
   return $python_line;
}

sub _conditions() {
   my ($condition) = @_;
   $condition =~ s/\$//g;
   return $condition;
}

sub _string_formatting() {
   my ($line) = @_;
   my $string = "";
   my $variable_search_regex = qr/\$[^\W]+(?:\s*(?:\*|\+|\/|-|\*\*|%)\s*\$[^\W]+)*/;    #store the regex to collect variables from a string
   my @regex_matches = ($line =~ /(".*?"|$variable_search_regex)/g);  
   #match for each subsection of print string, basically removes all concats

   my @var_formatting = ();
   foreach my $match (@regex_matches) {
      $string .= $match;             #concat all substrings into one
      $string =~ s/([^\\]|^)"/$1/g;  #removes all quote char
      $string =~ s/([^\\]|^)"/$1/g;  #removes all quote char, run twice because can't use lookbehind
      #all print strings are now one long string without concats
   }
   $string = "\"" . $string . "\"";      #adds quotes to the begin and end of whole string
   @var_formatting = ($string =~ /($variable_search_regex)/g); #collect variables for new formatting
   my $i = 0;                                      #counter variable
   $string =~ s/($variable_search_regex)/"{".$i++."}"/eg;     #adds formatting to the string
   $string .= ".format(";                     #adds the format to variables
      foreach my $var (@var_formatting) {
         $var =~ s/\$//g;
         $string .= "$var,";                  #adding in var at a time
      }
      $string =~ s/,$//;
      $string .= ")";                            #close off the format parentheses
      return $string;
}

sub _print() {
   
   my ($line) = @_;
   chomp ($line);
   my $python_line = &_insert_indentation();
   $line =~ s/\\n";\s*$/";/;              #removes the ending newline in perl's version
   $line =~ s/^\s*print\s*//g;            #remove to leave only string component
   $python_line .= "print " . &_string_formatting($line) . "\n";
   return $python_line;          #add finishing touches to print line
}

sub _insert_indentation() {
my ($indent_num) = $tab_indent;        
   my $indent = "";             #empty indent string
   for (; $indent_num > 0; $indent_num--) {
      $indent .= "\t";
   }
   return $indent;               #to be added onto the beginning of every $python line
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
