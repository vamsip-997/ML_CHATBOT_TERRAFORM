outer_function() {
    echo "This is outer function."

    inner_function() {
        echo "This is inner function."
    }

    # Call inner function
    inner_function
}

# Call outer function
outer_function


#!/bin/bash

outer() {
  echo "Outer function started."

  inner() {
    echo "Inner function running..."
  }

  # Call inner function
  inner
  echo "Outer function ended."
}

# Call outer function
outer



🌼 Example 2 — Real Example (Login Simulation)
#!/bin/bash

login_system() {
  echo "Welcome to Login System"

  ask_credentials() {
    echo "Enter username:"
    read user
    echo "Enter password:"
    read pass
    echo "Checking credentials..."
    sleep 1
    echo "Login successful ✅"
  }

  ask_credentials
}

login_system


✅ Output:

Welcome to Login System
Enter username:
ravi
Enter password:
ravi123
Checking credentials...
Login successful ✅

🌻 Example 3 — Nested Function with Return Values
#!/bin/bash

math_operations() {
  add() {
    sum=$(( $1 + $2 ))
    echo $sum
  }

  result=$(add 10 20)
  echo "Sum is: $result"
}

math_operations


✅ Output:

Sum is: 30

🌺 Example 4 — Nested Function Used for Validation
#!/bin/bash

create_user() {
  echo "Enter username:"
  read uname

  validate_name() {
    if [ -z "$uname" ]; then
      echo "Username cannot be empty ❌"
    else
      echo "Username '$uname' is valid ✅"
    fi
  }

  validate_name
}

create_user


✅ Output:

Enter username:
rishi
Username 'rishi' is valid ✅

⚙️ Key Points to Remember
Concept	Meaning
Nested Function	Function defined inside another function
Scope	Inner function only available after outer is called
Reusability	You can define logic sections separately
Execution Order	Inner runs only when outer is called
Useful For	Validation, Sub-Tasks, Modular scripts
🧩 Bonus Example (Practical)
#!/bin/bash

main_task() {
  echo "Starting backup process..."

  check_backup_folder() {
    if [ ! -d /tmp/backup ]; then
      mkdir /tmp/backup
      echo "Backup folder created."
    else
      echo "Backup folder already exists."
    fi
  }

  check_backup_folder
  echo "Backup process complete ✅"
}

main_task