Perfect 👍 That script in the image automatically creates multiple directories using a for loop in Bash.
Let’s go through multiple similar small automation examples like this — for both directories and files 👇

🧩 Example 1 — Create Multiple Directories
#!/bin/bash

echo "Enter the directory name base:"
read dirname

for ((i=1; i<=5; i++))
do
  mkdir ${dirname}_$i
done


🧠 Output:
If you enter project, it creates:

project_1  project_2  project_3  project_4  project_5

🧩 Example 2 — Create Multiple Files
#!/bin/bash

echo "Enter the base filename:"
read fname

for ((i=1; i<=5; i++))
do
  touch ${fname}_$i.txt
done


🧠 Output:
If you enter report, it creates:

report_1.txt  report_2.txt  report_3.txt  report_4.txt  report_5.txt

🧩 Example 3 — Create Directory and File Inside Each
#!/bin/bash

echo "Enter the project name:"
read pname

for ((i=1; i<=3; i++))
do
  mkdir ${pname}_$i
  touch ${pname}_$i/${pname}_file.txt
done


🧠 Output:

project_1/project_file.txt
project_2/project_file.txt
project_3/project_file.txt

🧩 Example 4 — Create Directories Based on User Input
#!/bin/bash

echo "How many folders do you want?"
read n

for ((i=1; i<=n; i++))
do
  echo "Enter folder name $i:"
  read name
  mkdir $name
done


🧠 Output:
Creates as many folders as the user wants with custom names.

🧩 Example 5 — Create Files with Today’s Date
#!/bin/bash

today=$(date +%Y-%m-%d)

for ((i=1; i<=3; i++))
do
  touch "log_${today}_$i.txt"
done


🧠 Output:

log_2025-11-04_1.txt
log_2025-11-04_2.txt
log_2025-11-04_3.txt

🇮🇳 Telugu Explanation
Command	Meaning	Telugu Explanation
mkdir	Make directory	కొత్త ఫోల్డర్ సృష్టిస్తుంది
touch	Create empty file	కొత్త ఖాళీ ఫైల్ సృష్టిస్తుంది
${var}_$i	Variable + loop number	ప్రతి లూప్‌లో కొత్త పేరు వస్తుంది
for ((i=1; i<=5; i++))	Loop 5 times	5 సార్లు లూప్ తిరుగుతుంది

Would you like me to add one combined automation script that creates both folders and files