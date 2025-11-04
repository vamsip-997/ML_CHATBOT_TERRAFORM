#!/bin/bash
echo "Choose your drink:"
echo "1. Coffee"
echo "2. Tea"
echo "3. Water"
echo "4. Juice"

read -p "Enter your choice (1-4): " choice

case "$choice" in
    1)
        echo "You selected Coffee - That will be $3.50"
        ;;
    2)
        echo "You selected Tea - That will be $2.50"
        ;;
    3)
        echo "You selected Water - That will be $1.00"
        ;;
    4)
        echo "You selected Juice - That will be $2.75"
        ;;
    *)
        echo "Invalid selection - Please choose a number between 1 and 4"
        ;;
esac