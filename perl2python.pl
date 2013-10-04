#!/usr/bin/perl -w

@overhead_code = ();
@python_code = ();
$tab_indent = 0;
$control_flow_keywords = qr/if|elsif|else|while|for(?:each)?/;
$perl_syntax_convention = qr/[\$@%&]/;
$operator_types = qr/(?:\+|\-|\*|\/|\.|%|\*\*)?=~?/;
$variable_assignment_regex = qr/^\s*(?:$perl_syntax_convention(.*?)\s*($operator_types)\s*(.*)?|\$.*?(?:\+\+|\-\-));\s*$/;
$perl_in_a_string = "";
#%variable_types = ();

while ($line = <>) {
   $perl_in_a_string .= $line;                              #concat all lines in perl file together
}
$perl_in_a_string =~ s/\}/}\n/g;                             #make sure closing curly brackets are on their own line
#print "$perl_in_a_string";
@perl_code = split (/(?<=\n)/, $perl_in_a_string);
#print @perl_code;

&_translation("");                                            #translate perl to python

&insert_libs(@overhead_code);                               
print @python_code;                                         #print python for the world to see
exit;

sub _inc_decrement_operator() {
   my ($operation) = @_;
   my $python_line = &_insert_indentation();
   $operation =~ /^\s*\$(.*?)(?:\+|\-)(\+|\-)/;
   my $variable = $1;
   $variable = &_variable($variable);
   $python_line .= "$variable = $variable $2 1\n";
   return $python_line;
}

sub _chomp() {
   my ($line) = @_;
   $line =~ /chomp\s*(.*?)\s*;/;
   my $variable  = $1;
   $variable = &_variable($variable);
   my $python_line = &_insert_indentation() . "$variable = $variable.rstrip()\n";
   return $python_line ;
}

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
      $python_line .= $control_statement . ":\n";
   }
   elsif ($control_statement =~ /for(?:each)?/) {
      if ($condition =~ /^\((.*?;.*?;.*?)\)$/) {                                   #C style for loops
         my @for_components = split(/;/, $1);       #break into 3 parts for easier processing
         my $initialisation = $for_components[0];
         $initialisation = &_variable_assignment($initialisation);
         my $condition = &_conditions($for_components[1]);
         my $increment = &_variable_assignment($for_components[2]);
         $python_line .= "while $condition:\n";                            #initialisation is above the while statement
         $python_line = "$initialisation" . $python_line . "$increment\n";          #hack to pass the increment part in return
                                                                                    #gets pulled apart in above function
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
            &_add_overhead_code("import sys");                 #import sys
         }
         elsif ($sequence =~ /\$\#ARGV/) {
            $sequence = "range(len(sys.argv) - 1)";
            &_add_overhead_code("import sys");
         }
         elsif ($sequence =~ /([0-9]+)\s*\.\.\s*([0-9]+)/) {
            my $begin = $1;
            my $end = $2;
            $end++;                                #python range is not end inclusive
            $sequence = "range($begin, $end)";    #xrange does not use as much memory as range
         }
         $sequence =~ s/[\$@]//g;
         $python_line .= "for " . $control_variable . " in " . $sequence . ":\n";
      }
   }
   elsif ($control_statement =~ /while/ && $condition =~ /\(\s*\$(\w+)\s*=\s*<>\s*\)/) {
      $python_line .= "for $1 in fileinput.input():\n";
      &_add_overhead_code("import fileinput");
   }
   elsif ($control_statement =~ /while/ && $condition =~ /\(\s*\$(\w+)\s*=\s*<STDIN>\s*\)/) {
      $python_line .= "for $1 in sys.stdin:\n";
   }
   else {
      
      $python_line .= $control_statement . " " . &_conditions($condition) . ":\n";
      $python_line =~ s/elsif/elif/;               #change perl elsif to python elif
   }                     
   return $python_line;
}

sub _return_type() {                                                                #attempt to determine the return type
   my ($operation) = @_;
   if ($operation =~ /".*?"/) {
      return "string";
   }
   elsif ($operation =~ /sys.stdin.readline\(\)/) {
      return "string";
   }
   else {
      return "numeric";
   }
}

sub _variable_assignment() {
   my ($line) = @_;
   my $python_line = &_insert_indentation();
   if ($line =~ /^\s*\$.*?(?:\+\+|\-\-);?\s*$/) {                                       #inc/decrement statements
      $python_line = &_inc_decrement_operator($line);
   }
   elsif ($line =~ /^\s*(?:my)?\s*$perl_syntax_convention(.*?)\s*($operator_types)\s*([^;]*)?/) {
      my $variable = "";
      my $assignment_operator = "";
      my $operation = "";
      $line =~ /^\s*(?:my)?\s*$perl_syntax_convention(.*?)\s*($operator_types)\s*([^;]*)?/;        #collect and split line
      $variable = $1;                                                                  #left side of the =
      $assignment_operator = $2;                                                       #the [+-*/.]=~? operator
      $operation = $3;                                                                 #right side of the =
      $variable = &_variable_declaration($variable);                                   #translate the 3 parts
      $assignment_operator = &_assignment_operation($variable, $assignment_operator);
      $operation = &_variable_operation($variable, $operation);
      #$variable_types{$variable} = &_return_type($operation);                          #allocate type to variable
      $python_line .= "$variable$assignment_operator$operation\n";
   }
   return $python_line;
}

sub _variable_operation() {         #handles all things to do with variable operations
   my ($variable, $operation) = @_;
   if ($operation =~ /<STDIN>/) {
      $operation =~ s/<STDIN>/sys.stdin.readline()/;
      &_add_overhead_code("import sys");
   }
   elsif ($operation =~ /\/(.*?)\/(.*?)\//) {         #re.sub or tr
      $operation = "re.sub(r'$1', '$2', $variable)";
      &_add_overhead_code("import re");
   }
   elsif ($operation =~ /\/(.*?)\//) {                #re.match
      $operation = "re.match(r'$1', $variable)";
      &_add_overhead_code("import re");
   }
   elsif ($operation =~ /\(?([0-9]+)\.\.([0-9]+)\)?/) { #range translation
      $operation = "range($1, $2)";
   }
   elsif ($operation =~ /unshift\s*\(@(.*?)\s*,\s*(.*?)\)/) {
      $operation = "$1.insert(0,$2)";
   }
   elsif ($operation =~ /shift\s*\(@(.*?)\)/) {
      $operation = "$1.pop(0)";
   }
   elsif ($operation =~ /pop\s*\(@(.*?)\)/) {
      $operation = "$1.pop(-1)";
   }
   elsif ($operation =~ /push\s*\(@(.*?)\s*,\s*(.*?)\)/) {
      $operation = "$1.append($2)";
   }
   $operation =~ s/$perl_syntax_convention(?=\S)//g;
   return "($operation)";
}

sub _assignment_operation() {       #expands out compound operators if need be
   my ($variable, $assignment_operator) = @_;
   if ($assignment_operator =~ /^((?:\+|\-|\*|\/|\.|%|\*\*)=)$/) {
      return " = $variable $1 ";
   }
   else {                           #catches = and =~
      return " = ";
   }
}

sub _variable() {                   #handle atomic variable translation, need to utilse more
   my ($variable) = @_;
   $variable =~ s/$perl_syntax_convention//;
   return $variable;
}
sub _variable_declaration() {       #handles variable declarations, decides where to declare the global/local stuff
   my ($variable) = @_;
   if ($variable =~ /^\s*my\s*/) {
      #not done yet
   }
   else {

   }
   $variable =~ s/$perl_syntax_convention//;
   return $variable;
}

sub _conditions() {
   my ($condition) = @_;
   my $string_comparators = qr/eq|ne|lt|le|gt|ge/;
   my $numeric_comparators = qr/==|!=|<=|>=|<|>/;

   $condition =~ s/\$//g;                                                              #remove $ from variables
   if ($condition =~ /\(\s*(\w+.*?)\s*($numeric_comparators|$string_comparators)\s*(.*?)\)/) {; #if it matches the structure
      my $variable = $1;
      my $comparator = $2;
      my $value = $3;
      
      if ($comparator =~ /$string_comparators/ ) {  #convert if need be
         $variable =~ s/$variable/str($variable)/;
      }
      if ($comparator =~ /$numeric_comparators/ ) {
         $variable =~ s/(\w+)/float($1)/;                                         #so far always convert to float
      }
      $condition = "$variable $comparator $value";                                           #restitch together
   }
   $condition =~ s/ eq / == /g;
   $condition =~ s/ ne / != /g;
   $condition =~ s/ lt / < /g;
   $condition =~ s/ le / <= /g;
   $condition =~ s/ gt / > /g;
   $condition =~ s/ ge / >= /g;
   return $condition;
}

sub _string_formatting() {
   my ($line) = @_;
   my $string = "";
   my $variable_search_regex = qr/\$[^\W]+(?:\s*(?:%|\*|\+|\/|-|\*\*)\s*\$[^\W]+)*/; #store the regex to collect variables from a string
   if ($line =~ /".*?"/) {
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
         $string .= "$var,";                                   #adding in var at a time
      }
      $string =~ s/,$//;
      $string .= ")";                                          #close off the format parentheses
      if ($string =~ /\.format\(\)/) {
         $string =~ s/\.format\(\)//;                          #remove .format() if its not used
      }
   }
   else {
      
      $string = &_variable_operation("", $line);               #for anything other than strings,
      $string = "str($string)";                                #make them strings
   }
   return $string;
}

sub _print() {
   
   my ($line) = @_;
   chomp ($line);
   my $python_line = &_insert_indentation();
   $line =~ s/^\s*print\s*//g;            #remove to leave only string component
   $line =~ s/;\s*$//;
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
      splice (@python_code, 1, 0, "$lib\n");
   }
}

#add libraries to python if not added yet
sub _add_overhead_code() {
   my ($library) = @_;  #input library
   my $seen = 0;
   #loop through each lib in list so far
   foreach $import (@overhead_code) {
      if ($import eq $library) {
         $seen = 1;
         last;
      }
   }
   if ($seen == 0) {
      unshift (@overhead_code, $library);    #unshift because we want #!/usr/bin/python2.7 -u on top
   }
}

sub _translation() {
   my ($closing_block_code) = @_;
   my $recurse = 0;                                            #flag to indicate when to recurse
   my %variable_scope = ();
   my $push_to_next_level = "";
   #@perl_code and @python_code are global variables
   while (my $line = shift @perl_code) {
      my $python_line = "";
         #account for different scenarios in perl
      if ($line =~ /^\s*#!\/usr\/bin\/perl\s*\-w/) {
         &_add_overhead_code("#!/usr/bin/python2.7 -u");
         $python_line = "";                                    #need to give the push function something
      }
      elsif ($line =~ /^\s*print.*/) {
         $python_line = &_print($line);
         &_add_overhead_code("import sys");
      }
      elsif ($line =~ /$variable_assignment_regex/) {
         $python_line = &_variable_assignment($line);          #translate variable assignments
      }
      elsif ($line =~ /^\s*(?:$control_flow_keywords)/) {
         $python_line = &_control_flow_statement($line);
         if ($python_line =~ /.*?\n.*?\n\s*(.*?)\n/) {         #check for C style loops conversion, need to do something else
            $push_to_next_level .= $1;                         #like, add increment at the end of the block
            $python_line =~ s/(.*?\n.*?\n)\s*.*?\n/$1/;
         }
         $recurse = 1;                                         #recurse one step down
         $tab_indent++;
      }
      elsif ($line =~ /^\s*\}\s*$/) {
         $python_line = &_insert_indentation() . $closing_block_code if $closing_block_code ne "";                                    #python equiv is just tab decrement
         $recurse = -1;                                        #return one step up
         $tab_indent--;
      }
      elsif ($line =~ /^\s*last\s*;\s*$/) {
         $python_line = &_insert_indentation() . "break\n";    #change perl's last into python's break
      }
      elsif ($line =~ /^\s*next\s*;\s*$/) {
         $python_line = &_insert_indentation() . "continue\n"; #change perl's next into python's continue
      }
      elsif ($line =~ /^\s*$/) {
         $python_line = "\n";                                  #empty lines!
      }
      elsif ($line =~ /^\s*#/) {
         $python_line = $line;                                 #Comments are identical, only works if they are on their own
      }
      elsif ($line =~ /^\s*chomp/) {
         $python_line = &_chomp($line);                        #translate chomp
      }
      else {
         $python_line = &_variable_operation("", $line) . "\n";#pass it to _variable_operation to see if it can do anything
         $test_line = $line;
         $test_line =~ s/$perl_syntax_convention(?=\S)//g;     #if not, then
         if ($test_line eq $python_line) {
            $python_line = "#" . $line;                        #comment it out
         }
      }
      push (@python_code, $python_line);                       #add python_line into array
      if ($recurse == 1) {                                     #perform recursion after pushing this line
         &_translation("$push_to_next_level");
         $push_to_next_level = "";
         $recurse = 0;                                         #reset recurse event
      }
      elsif ($recurse == -1) {
         return;
      }
   }
   return;                                                     #when perl_code runs out, finish translation,
                                                               #regardless of how deep
}
