#!/bin/bash
i=0 
while [ $i -lt 26 ];
do  cp alchemical-XXX.mdp alchemical-${i}.mdp;
vi -c :%s/XXX/${i}/g -c :wq! alchemical-${i}.mdp; 
((i+=1)); 
done
