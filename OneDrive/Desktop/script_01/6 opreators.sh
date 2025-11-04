#!/bin/bash

# Arithmetic Operators Example
echo "Simple Calculator Example"

# Variables
a=10
b=5

# Addition
echo "Addition: $a + $b = $((a + b))"           

# Subtraction
echo "Subtraction: $a - $b = $((a - b))"

# Multiplication
echo "Multiplication: $a * $b = $((a * b))"

# Division
echo "Division: $a / $b = $((a / b))"

# Modulus (Remainder)
echo "Remainder: $a % $b = $((a % b))"             





# Comparison Operators
if [ $a -gt $b]
then
    echo "$a is greater than $b"
fi

if [ $b -lt $a ]
then
    echo "$b is less than $a"
fi

if [ $a -eq 10 ]
then
    echo "$a is equal to 10"
fi