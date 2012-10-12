/{{/ {  
   =;                     #   print the line number
   s/\(.*\)/{r \1/;        #   change pattern to 'r{ '
   s/{{\(.*\)}}.*/\1/p;              #   delete rest to EOL, print
                          #   and a(ppend) a delete command
   a\
   d;}
 }
