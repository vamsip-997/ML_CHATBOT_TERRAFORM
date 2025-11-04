user_deletion.sh
🧩 2️⃣ User Deletion Script (user_deletion.sh)
We’ll see different versions 👇
🪶 Example 1 — Simple User Deletion

#!/bin/bash
echo "Enter username to delete:"
read uname
sudo userdel -r "$uname"
echo "User '$uname' deleted successfully ✅"
✅ Output
Enter username to delete:

ravi
User 'ravi' deleted successfully ✅
🪶 Example 2 — Using Function
#!/bin/bash
delete_user() {
  echo "Enter username to delete:"
  read uname
  sudo userdel -r "$uname"
  echo "User '$uname' deleted successfully ✅"
}


