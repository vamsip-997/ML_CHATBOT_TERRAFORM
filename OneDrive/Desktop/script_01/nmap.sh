

👉 nmap.sh — used to scan network or IP using the nmap command.

🧾 Example 1 – Simple Scan (2 lines)
#!/bin/bash
read -p "Enter IP or website: " ip; nmap "$ip"

✅ Output:
Enter IP or website: scanme.nmap.org
Starting Nmap 7.94 ( https://nmap.org )
Nmap scan report for scanme.nmap.org (45.33.32.156)
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
...


🧾 Example 2 – Fast Ping Scan (3 lines)
#!/bin/bash
echo "Enter IP range (e.g. 192.168.1.0/24):"
read range
nmap -sn "$range"

✅ Output:
Enter IP range (e.g. 192.168.1.0/24):
192.168.1.0/24
Nmap scan report for 192.168.1.1
Host is up (0.003s latency).
Nmap done: 256 IP addresses (10 hosts up)


🧾 Example 3 – Specific Port Scan
#!/bin/bash
read -p "Enter target IP: " ip
read -p "Enter port: " port
nmap -p "$port" "$ip"

✅ Output:
Enter target IP: 192.168.1.10
Enter port: 22
PORT   STATE SERVICE
22/tcp open  ssh


🧾 Example 4 – Shortest (1 line)
#!/bin/bash
nmap scanme.nmap.org

✅ Instantly scans that host.

⚙️ Run Steps


Save file as nmap.sh


Give permission:
chmod +x nmap.sh



Run:
./nmap.sh




💡 Tip:
You can install nmap if not available:
sudo apt install nmap     # Ubuntu
# or
winget install nmap       # Windows Git Bash (if using Winget)





Perfect 👍 you’re showing a script named nmap.sh, and inside it you’re trying to build a menu (1: Normal Scan, 2: TCP Scan, 3: UDP Scan) using a case statement.

Let’s complete that script in a simple and working version 👇

🧾 Simple nmap.sh Example with case
#!/bin/bash
# usecase: read hostname, choose nmap scan type

echo "Enter the hostname or IP:"
read hostname

echo "Enter your system password:"
read -s systempassword

nmapfunction() {
  echo "Choose your scan type:"
  echo "1. Normal Scan"
  echo "2. TCP Scan"
  echo "3. UDP Scan"
  read -p "Enter your choice: " choice

  case $choice in
    1)
      echo "Running Normal Scan..."
      nmap "$hostname"
      ;;
    2)
      echo "Running TCP Scan..."
      nmap -sT "$hostname"
      ;;
    3)
      echo "Running UDP Scan..."
      sudo -S <<< "$systempassword" nmap -sU "$hostname"
      ;;
    *)
      echo "Invalid choice ❌"
      ;;
  esac
}

# Call the function
nmapfunction

▶️ How it Works

Asks for hostname / IP

Asks for system password (for sudo UDP scan)

Displays 3 options

1 → Normal Scan

2 → TCP Scan

3 → UDP Scan

Runs the correct nmap command based on your choice.

🧩 Example Run
Enter the hostname or IP:
scanme.nmap.org
Enter your system password:
Choose your scan type:
1. Normal Scan
2. TCP Scan
3. UDP Scan
Enter your choice: 2
Running TCP Scan...
Starting Nmap 7.94 ( https://nmap.org )
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http

💡 Notes

nmap -sT → TCP connect scan

nmap -sU → UDP scan (needs sudo)

nmap (default) → normal scan

read -s hides password input