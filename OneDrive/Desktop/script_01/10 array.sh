#!/bin/bash

fruits=("apple" "banana" "cherry" kissmiss")
       0        1         2         3
echo "First fruit: ${fruits[0]}"
echo "fourth 

echo "Second fruit: ${fruits[1]}"
echo "Third fruit: ${fruits[2]}"
echo "Number of fruits: ${#fruits[@]}"
echo "Adding a new fruit: orange"
fruits+=("orange")

echo "Updated number of fruits: ${#fruits[@]}"
echo "Fruits after adding: ${fruits[@]}"
echo "All fruits: ${fruits[@]}"

 #or
 echo "All fruits: ${fruits[*]}"