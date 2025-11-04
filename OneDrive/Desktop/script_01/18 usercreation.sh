🧾 Simple User Creation Script Example
🔹 File name: user_create.sh
#!/bin/bash

# Simple script to create one user

echo "Enter username: "
read username

echo "Enter password: "
read password

# Create user
sudo useradd -m -s /bin/bash "$username"

# Set password
echo "$username:$password" | sudo chpasswd

echo "✅ User $username created successfully!"


🧠 Explanation (Telugu + English)
LineExplanation#!/bin/bashIdi 
shell script ani system ki cheptundi.echo "Enter username:"Message chupistundi.read usernameUser type chesina name ni variable username lo save chestundi.sudo useradd -m -s /bin/bash "$username"Kotha user ni create chestundi with home folder & bash shell.`echo "$username:$password"sudo chpasswd`echo "User created successfully!"Success message chupistundi.

▶️ Run Command
bash user_create.sh

or
./user_create.sh

(but first make it executable)
chmod +x user_create.sh


🧩 Example Output
Enter username:
ravi
Enter password:
ravi123
✅ User ravi created successfully!


Would you like same easy example but with multiple users in loop (for loop) version next?
Example: create 3 users automatically (user1, user2, user3)?



🧾 User Creation Script with For Loop Example
# usecase: for loop - username input - password - choice

for ((i=0;i<=2;i++))
do
  echo "Enter your choice: "
  read choice

  if [ $choice -eq 1 ]
  then
    echo "Enter the username: "
    read username

    echo "Enter the password: "
    read password

    sudo useradd -m -s /bin/bash $username
    echo "$username:$password"
  fi
done
