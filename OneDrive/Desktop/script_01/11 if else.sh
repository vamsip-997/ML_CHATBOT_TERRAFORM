#!/bin/bash
# Simple if-else example

echo -n "Enter a number: "
read number

if [ $number -gt 0 ]; then

    echo "The number is positive"
else
    echo "The number is zero or negative"
fi
fi