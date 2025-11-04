#!/bin/bash
x=10
y=20

if [ $x -lt $y ]
then
  echo "x is smaller"
else
  echo "x is greater or equal"
fi


# Output:x is smaller

touch myfile.txt

if [ -f myfile.txt ]
then
  echo "File exists"
else
  echo "File not found"
fi
➡️ Output: File exists




🔹 3. Check if directory exists
if [ -d /c/Users ]
then
  echo "Directory exists"
else
  echo "No directory"
fi
➡️ Output: Directory exists


🔹 4. Check if string is empty or not
name="rishi"

if [ -n "$name" ]
then
  echo "String is not empty"
else
  echo "String is empty"
fi


🔹 5. Combine conditions (AND / OR)
a=5
b=10

if [ $a -gt 0 ] && [ $b -gt 0 ]
then
  echo "Both positive"
fi



&& → means "if true, then run next"
|| → means "if false, then run next"



💡 Summary Table

Check Type
Command
Meaning
-f file
[ -f myfile.txt ]
File exists
-d dir
[ -d mydir ]
Directory exists
-e file
[ -e myfile.txt ]
File or directory exists
-n str
[ -n "$var" ]
String not empty
-z str
[ -z "$var" ]
String empty
-eq
[ $a -eq $b ]
Equal numbers
-ne
[ $a -ne $b ]
Not equal
-lt
[ $a -lt $b ]
Less than
-gt
[ $a -gt $b ]
Greater than