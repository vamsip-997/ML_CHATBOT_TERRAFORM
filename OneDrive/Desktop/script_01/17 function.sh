🧩 Syntax
Two common ways to define a function:

✅ Method 1:
function function_name() {
  commands
}

✅ Method 2:
function_name() {
  commands
}


🌱 Example 1 — Simple Function
Filename: function.sh
#!/bin/bash

greet() {
  echo "Hello! Welcome to Git Bash scripting 😊"
}

# Call the function
greet

▶️ Run:
bash function.sh
✅ Output:
Hello! Welcome to Git Bash scripting 😊


🌼 Example 2 — Function with Parameters
#!/bin/bash

say_hello() {
  echo "Hello $1, how are you?"
}

say_hello Rishi
say_hello Teja
✅ Output:
Hello Rishi, how are you?
Hello Teja, how are you?
🧠 Note: $1 → first argument, $2 → second, etc.


🌻 Example 3 — Function Returning a Value (via echo)
#!/bin/bash

add_numbers() {
  sum=$(( $1 + $2 ))
  echo $sum
}

# Capture the return value
result=$(add_numbers 10 20)
echo "The sum is: $result"
✅ Output:
The sum is: 30





🌺 Example 5 — Function with Loop Inside
#!/bin/bash

print_numbers() {
  for i in {1..5}
  do
    echo "Number: $i"
  done
}

print_numbers
✅ Output:
Number: 1
Number: 2
Number: 3
Number: 4
Number: 5

