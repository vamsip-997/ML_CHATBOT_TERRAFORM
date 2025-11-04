#!/bin/bash
# Comprehensive Array Examples in Bash

echo "Array Examples in Bash"
echo "--------------------"

# 1. Declaring and initializing an array
echo "1. Basic Array Declaration:"
fruits=("Apple" "Banana" "Orange" "Mango" "Grape")
echo "Fruits array: ${fruits[@]}"

# 2. Accessing specific elements
echo -e "\n2. Accessing Elements:"
echo "First fruit: ${fruits[0]}"
echo "Third fruit: ${fruits[2]}"
echo "Last fruit: ${fruits[-1]}"

# 3. Array length
echo -e "\n3. Array Length:"
echo "Number of fruits: ${#fruits[@]}"

# 4. Slicing arrays
echo -e "\n4. Array Slicing:"
echo "First two fruits: ${fruits[@]:0:2}"
echo "From second fruit, take 3: ${fruits[@]:1:3}"

# 5. Adding elements
echo -e "\n5. Adding Elements:"
fruits+=("Pineapple")
fruits+=("Strawberry")
echo "After adding: ${fruits[@]}"

# 6. Iterating through array
echo -e "\n6. Array Iteration:"
echo "List of all fruits:"
for fruit in "${fruits[@]}"
do
    echo "- $fruit"
done

# 7. Array with indices
echo -e "\n7. Array with Indices:"
declare -A colors
colors[red]="#FF0000"
colors[green]="#00FF00"
colors[blue]="#0000FF"

for color in "${!colors[@]}"
do
    echo "$color: ${colors[$color]}"
done

# 8. Array operations
echo -e "\n8. Array Operations:"
numbers=(1 2 3 4 5)
echo "Original numbers: ${numbers[@]}"
# Double each number
for ((i=0; i<${#numbers[@]}; i++))
do
    numbers[$i]=$((${numbers[$i]} * 2))
done
echo "Numbers doubled: ${numbers[@]}"

# 9. Finding elements
echo -e "\n9. Finding in Array:"
search="Banana"
if [[ " ${fruits[@]} " =~ " ${search} " ]]; then
    echo "'$search' found in fruits array"
else
    echo "'$search' not found in fruits array"
fi

# 10. Removing elements (by creating a new array)
echo -e "\n10. Removing Elements:"
remove="Orange"
new_fruits=()
for fruit in "${fruits[@]}"
do
    if [ "$fruit" != "$remove" ]; then
        new_fruits+=("$fruit")
    fi
done
echo "After removing $remove: ${new_fruits[@]}"