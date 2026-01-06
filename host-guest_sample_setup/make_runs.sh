#!/bin/bash
i=0
while [ $i -lt 6 ];
do  cp runXXX.sh run-${i}.sh;
vi -c :%s/XXX/${i}/g -c :wq! run-${i}.sh;
((i+=1));
done
