#!/bin/bash
# Thanks to https://stackoverflow.com/questions/24641948/merging-csv-files-appending-instead-of-merging/24643455
OutFileName="combined.csv"                       # Fix the output name
i=0                                       # Reset a counter
for filename in raw-data/*.csv; do 
 if [ "$filename"  != "$OutFileName" ] ;      # Avoid recursion 
 then 
   if [[ $i -eq 0 ]] ; then 
      head -1  "$filename" >   "$OutFileName" # Copy header if it is the first file
   fi
   tail -n +2  "$filename" >>  "$OutFileName" # Append from the 2nd line each file
   i=$(( $i + 1 ))                            # Increase the counter
 fi
done
