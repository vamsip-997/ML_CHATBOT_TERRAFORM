#!/bin/bash
# Comprehensive demonstration of if-else statements in Bash

echo "==== Basic if statement ===="
read -p "Enter your age: " age
if [ $age -ge 18 ]
then
    echo "You are an adult"
fi

echo -e "\n==== if-else statement ===="
read -p "Enter a number: " num
if [ $((num % 2)) -eq 0 ]
then
    echo "$num is even"
else
    echo "$num is odd"
fi

echo -e "\n==== if-elif-else statement ===="
read -p "Enter your score (0-100): " score
if [ $score -ge 90 ]
then
    echo "Grade: A"
elif [ $score -ge 80 ]
then
    echo "Grade: B"
elif [ $score -ge 70 ]
then
    echo "Grade: C"
else
    echo "Grade: F"
fi

echo -e "\n==== Nested if statements ===="
read -p "Enter your age: " age
read -p "Do you have a license? (yes/no): " license
if [ $age -ge 18 ]
then
    if [ "$license" = "yes" ]
    then
        echo "You can drive"
    else
        echo "You need to get a license first"
    fi
else
    echo "You are too young to drive"
fi

echo -e "\n==== Multiple conditions (AND) ===="
read -p "Enter username: " username
read -p "Enter password: " password
if [ "$username" = "admin" ] && [ "$password" = "secret" ]
then
    echo "Login successful"
else
    echo "Login failed"
fi

echo -e "\n==== Multiple conditions (OR) ===="
read -p "Enter a fruit name: " fruit
if [ "$fruit" = "apple" ] || [ "$fruit" = "orange" ]
then
    echo "This is a common fruit"
else
    echo "This might be an exotic fruit"
fi

echo -e "\n==== Case insensitive comparison ===="
read -p "Are you happy? (yes/no): " answer
if [ "${answer,,}" = "yes" ]  # Convert to lowercase
then
    echo "That's great!"
else
    echo "Hope you feel better soon!"
fi

echo -e "\n==== String comparison ===="
read -p "Enter first string: " str1
read -p "Enter second string: " str2
if [ "$str1" = "$str2" ]
then
    echo "Strings are equal"
else
    echo "Strings are different"
fi

echo -e "\n==== File test operators ===="
read -p "Enter a filename: " filename
if [ -f "$filename" ]
then
    echo "File exists"
    if [ -w "$filename" ]
    then
        echo "And is writable"
    fi
else
    echo "File does not exist"
fi