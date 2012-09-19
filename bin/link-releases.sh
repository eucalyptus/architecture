#!/bin/bash
for f in features/*/3.2; do ln -sfv $f releases/3.2/$(dirname ${f/features/}); done
for f in features/*/3.3; do ln -sfv $f releases/3.3/$(dirname ${f/features/}); done
