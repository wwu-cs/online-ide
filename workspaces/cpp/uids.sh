#!/bin/bash
for i in $(seq 1001 5000); do
  echo "user$i:x:$i:1000:,,,:/home/project:/bin/bash"
done;
