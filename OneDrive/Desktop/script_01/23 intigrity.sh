🧾 Concept: What is File Integrity?

Integrity
 check means verifying if a file is modified or tampered after creation.
We do this by storing a file’s hash (unique fingerprint) and comparing it later.

👉 Example:
If file’s hash changes → someone edited or corrupted it.
If same hash → file is safe ✅


#!/bin/bash

echo "Enter file name:"
read file

old_hash=$(md5sum "$file")

echo "Now change the file and press Enter..."
read

new_hash=$(md5sum "$file")

if [ "$old_hash" = "$new_hash" ]; then
  echo "✅ File not changed"
else
  echo "⚠️ File changed!"
fi
✅ Output:
Enter file name:
test.txt
Now change the file and press Enter...
⚠️ File changed!
🛠️ Key Commands:
Command	Meaning
md5sum filename	Generates MD5 hash of the file
sha256sum filename	Generates SHA-256 hash of the file
diff <(md5sum file1) <(md5sum file2)	Compares hashes of two files

