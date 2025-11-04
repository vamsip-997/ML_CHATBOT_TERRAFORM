#!/bin/bash
# Demonstration of comparison operators in bash

echo "Enter a number: "
read number

# Greater than
if [ $number -gt 10 ]; then
    echo "$number is greater than 10"
fi

# Less than
if [ $number -lt 20 ]; then
    echo "$number is less than 20"
fi

# Greater than or equal to
if [ $number -ge 10 ]; then
    echo "$number is greater than or equal to 10"
fi

# Less than or equal to
if [ $number -le 20 ]; then
    echo "$number is less than or equal to 20"
fi

# Equal to
if [ $number -eq 15 ]; then
    echo "$number is equal to 15"
fi

# Not equal to
if [ $number -ne 15 ]; then
    echo "$number is not equal to 15"
fi

# Quick reference of operators:
echo "
Comparison Operators in Bash:
-gt : greater than
-lt : less than
-ge : greater than or equal to
-le : less than or equal to
-eq : equal to
-ne : not equal to"