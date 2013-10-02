#!/usr/bin/perl -w

@import_python_libs = ();

@python_code = ();
$tab_indent = 0;
#run through each line and transform $line to python as it goes
$control_flow_keywords = qr/if|elsif|else|while|for(?:each)?/;
$perl_syntax_convention = qr/[\$@%&]/;
$operator_types = qr/(?:\+|\-|\*|\/|\.|%|\*\*)/;

while ($line = <>) {
   #account for different scenarios in perl
   if ($line =~ "#!/usr/bin/perl -w") {
      $python_line = "#!/usr/bin/python2.7 -u\n";
   }
   elsif ($line =~ /^\s*print.*/) {
      $python_line = &_print($line);
      &add_lib("sys");
   }
   elsif ($line =~ /^\s*(my)?\s*$perl_syntax_convention\S+\s*$operator_types?=/) {
      $python_line = &_variable_assignment($line);
   }
   elsif ($line =~ /^\s*(?:$control_flow_keywords)/) {
      $python_line = &_control_flow_statement($line);
      $tab_indent++;                                        #translate the if statement first, then increment the tab count
   }
   elsif ($line =~ /^\s*\}\s*$/) {
      $tab_indent--;
      $python_line = "";                                    #python equiv is just tab decrement
   }
   elsif ($line =~ /^\s*last\s*;\s*$/) {
      $python_line = &_insert_indentation() . "break\n";    #change perl's last into python's break
   }
   elsif ($line =~ /^\s*$/) {
      $python_line = "\n";                                  #empty lines require no translation!
   }
   elsif ($line =~ /^\s*#/) {
      $python_line = $line;                                 #Comments are identical, only works if they are on their own
   }
   else {
      $python_line = "#" . $line;
   }
   #push converted python into array
   push (@python_code, $python_line);
}
&insert_libs(@import_python_libs);
print @python_code;

sub _control_flow_statement() {
   my ($line) = @_;
   my $condition = "";
   chomp ($line);
   my $python_line = &_insert_indentation();
   $line =~ /^\s*(\w+)/;
   my $control_statement = $1;
   $line =~ /$control_flow_keywords\s*(.*\(.*?\))\s*\{/;                        #collect only the conditions
   $condition = $1;
   if ($control_statement =~ /else/) {                      #else has no condition
      $python_line = $control_statement . ":\n";
   }
   elsif ($control_statement =~ /for(?:each)?/) {
      if ($condition =~ /^\(.*?;.*?;.*?\)$/) {                                   #C style for loops
         $condition =~ s/\((.*)\)/$1/;                      #remove the closing (), don't need them
         my @for_components = split(/;/, $condition);       #break into 3 parts for easier processing
         $for_components[0] =~ /^\$(\w+)\s*.*$/;            #collect var name, need to check for consistency later
         my $var = $1;
         $for_components[0] =~ /([0-9]+)\s*$/;              #collect begin of range
         my $begin_range = $1;
         $for_components[1] =~ /([0-9]+)\s*$/;              #collect end of range
         my $end_range = $1;
         $for_components[2] =~ /(-?\s*[0-9]+)\s*$/;         #collect incrementing
         my $increment = $1;
         $increment =~ s/\s//g;                             #remove any whitespaces in increment
         $python_line .= "for $var in range($begin_range, $end_range, $increment):\n";
      }
      else {                                                                     #sequence iteration style
         #types of sequences: array, range, (hash) still need to implement hash
         $condition =~ /(\$\w+)?\s*(\(.*?\))/;              #collect condition components
         my $control_variable = $1;
         my $sequence = $2;
         $control_variable =~ s/[\$]//g;     #remove perl syntax
         $control_variable =~ s/\s*my\s*//;  #the my keyword in the control variable is not needed
         if ($sequence =~ /\@ARGV/) {        #looping over built-in perl array
            $sequence = "sys.argv[1:]";
            &add_lib("sys");                 #import sys
         }
         elsif ($sequence =~ /([0-9]+)\s*\.\.\s*([0-9]+)/) {
            my $begin = $1;
            my $end = $2;
            $end++;                                #python range is not end inclusive
            $sequence = "xrange($begin, $end)";    #xrange does not use as much memory as range
         }
         $sequence =~ s/[\$@]//g;
         $python_line .= "for " . $control_variable . " in " . $sequence . ":\n";
      }
   }
   else {
      $python_line .= $control_statement . " " . &_conditions($condition) . ":\n";
      $python_line =~ s/elsif/elif/;               #change perl elsif to python elif
   }                         
   return $python_line;
}

sub _variable_assignment() {
   my ($line) = @_;
   my $python_line = &_insert_indentation();
   my $variable = "";
   my $assignment_operator = "";
   my $operation = "";
   $line =~ /^\s*($perl_syntax_convention\S*)\s*($operator_types?=)\s*(.*);$/;      #collect and split line
   $variable = $1;                                                                  #left side of the =
   $assignment_operator = $2;                                                       #the [+-*/.]= operator
   $operation = $3;                                                                 #right side of the =
   $variable = &_variable_declaration($variable);                                   #translate the 3 parts
   $assignment_operator = &_assignment_operation($variable, $assignment_operator);
   $operation = &_variable_operation($operation);
   $python_line .= "$variable$assignment_operator$operation\n";
   return $python_line;
}

sub _variable_operation() {         #handles all things to do with variable operations
   my ($operation) = @_;
   $operation =~ s/$perl_syntax_convention(?=\S)//g;
   return "($operation)";
}

sub _assignment_operation() {       #expands out compound operators if need be
   my ($variable, $assignment_operator) = @_;
   if ($assignment_operator =~ /^($operator_types)=$/) {
      return " = $variable $1 ";
   }
   else {
      return " = ";
   }
}

sub _variable_declaration() {       #handles variable declarations, decides where to declare the global/local stuff
   my ($variable) = @_;
   $variable =~ s/$perl_syntax_convention//;
   return $variable;
}

sub _conditions() {
   my ($condition) = @_;
   $condition =~ s/\$//g;
   return $condition;
}

sub _string_formatting() {
   my ($line) = @_;
   my $string = "";
   my $variable_search_regex = qr/\$[^\W]+(?:\s*(?:%|\*|\+|\/|-|\*\*)\s*\$[^\W]+)*/;    #store the regex to collect variables from a string
   my @regex_matches = ($line =~ /(".*?"|$variable_search_regex)/g);  
   #match for each subsection of print string, basically removes all concats

   my @var_formatting = ();
   foreach my $match (@regex_matches) {
      $string .= $match;                                    #concat all substrings into one
      $string =~ s/([^\\]|^)"/$1/g;                         #removes all quote char
      $string =~ s/([^\\]|^)"/$1/g;                         #removes all quote char, run twice because can't use lookbehind
      #all print strings are now one long string without concats
   }
   $string = "\"" . $string . "\"";                         #adds quotes to the begin and end of whole string
   @var_formatting = ($string =~ /($variable_search_regex)/g); #collect variables for new formatting
   my $i = 0;                                               #counter variable
   $string =~ s/($variable_search_regex)/"{".$i++."}"/eg;   #adds formatting to the string
   $string .= ".format(";                                   #adds the format to variables
      foreach my $var (@var_formatting) {
         $var =~ s/\$//g;
         $string .= "$var,";                                #adding in var at a time
      }
      $string =~ s/,$//;
      $string .= ")";                                       #close off the format parentheses
      return $string;
}

sub _print() {
   
   my ($line) = @_;
   chomp ($line);
   my $python_line = &_insert_indentation();
   $line =~ s/^\s*print\s*//g;            #remove to leave only string component
   $python_line .= "sys.stdout.write(" . &_string_formatting($line) . ")\n";
   return $python_line;                   #add finishing touches to print line
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
