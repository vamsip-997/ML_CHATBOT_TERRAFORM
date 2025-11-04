🧾 Example 1 – 2 lines
#!/bin/bash
read -p "Repo URL: " r; git clone "$r"


✅ Output:

Repo URL: https://github.com/user/repo.git
Cloning into 'repo'...



🧾 Example 2 – With folder name (3 lines)
#!/bin/bash
read -p "Repo URL: " r
read -p "Folder name: " f
git clone "$r" "$f"


✅ Output:

Repo URL: https://github.com/user/repo.git
Folder name: testrepo
Cloning into 'testrepo'...




🧾 Example 3 – Fixed repo (1 line)
#!/bin/bash
git clone https://github.com/torvalds/linux.git


✅ Output:

Cloning into 'linux'...


💡 Tip:
Run it using

chmod +x clonerepo.sh
./clonerepo.sh
