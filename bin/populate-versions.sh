#!/bin/bash
for f in features/*/* ; do 
  if [[ -d $f ]]; then 
    echo $f; vdir="versions/$(basename $f)"; 
    mkdir -p $vdir; 
    ( cd $vdir ; 
      ln -sf ../../$f $(basename $(dirname $f))
    ); 
  fi; 
done

