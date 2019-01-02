#!/bin/bash

./install.sh $1
if [[ ! $? -eq 0 ]]; then
  exit -1;
fi

./src/nw/nw $2
