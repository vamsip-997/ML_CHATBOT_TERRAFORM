#!/bin/bash
# breakcontinue.sh - break and continue examples
for ((i=0; i<=10; i++))
do
  echo "Enter your age: "
  read age

  if [ $age -lt 18 ]
  then
    echo "You are not allowed in party."
    break
  else
    echo "You are allowed in party."
  fi
done


#!/bin/bash

for i in {1..5}
do
  if [ $i -eq 3 ]
  then
    echo "Breaking at number $i"
    break
  fi
  echo "Number is $i"

done

#!/bin/bash

for i in {1..5}
do
  if [ $i -eq 3 ]
  then
    echo "Skipping number $i"
    continue
  fi
  echo "Number is $i"
done




echo "Continue example:"
for i in {1..5}; do
    if [ "$i" -eq 2 ]; 
    then
    echo "  skipping $i"
    continue
    fi
    echo "  i = $i"
done

echo
echo "Break example:"
for i in {1..5}; do
    if [ "$i" -eq 3 ]; 
    then
    echo "  breaking at $i"
    break
    fi
    echo "  i = $i"
done





for i in {1..10}
do
    if [ $i -eq 6 ]
    then
        echo "Breaking the loop at $i"
        break
    fi
    echo "Current number: $i"
done