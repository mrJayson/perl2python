#!/bin/bash

pwd=`pwd`

dflag=0

for arg in $@
do
   if [ $arg == '-d' ]
   then
      dflag=1
   fi
done

for folder in subset?
do
   for file in $folder/*.pl
   do
      file=`echo $file | sed s/'.pl$'/''/g`
      echo "testing $file"
      if [ -e "$file.input" ]
         then
         output1=`diff <(perl $file.pl < $file.input) <(python $file.py < $file.input)`
         output2=`diff <(python <(./perl2python.pl $file.pl) < $file.input) <(python $file.py < $file.input)`
         output3=`diff <(python <(./perl2python.pl $file.pl) < $file.input) <(perl $file.pl < $file.input)`
      else
         output1=`diff <(perl "$file.pl") <(python "$file.py")`
         output2=`diff <(./perl2python.pl "$file.pl" | python) <(python "$file.py")`
         output3=`diff <(./perl2python.pl "$file.pl" | python) <(perl "$file.pl")`
      fi
      if [ "$output1" != "" ] || [ "$output2" != "" ] || [ "$output3" != "" ]
      then
         echo "ERROR IN $file"
         if [ $dflag -eq 1 ]
         then
            echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
            echo "output1"
            echo $output1
            echo "output2"
            echo $output2
            echo "output3"
            echo $output3
            echo
            echo
            echo
            echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
         fi
      fi
   done
done
