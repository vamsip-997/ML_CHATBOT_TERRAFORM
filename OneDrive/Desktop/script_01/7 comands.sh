#!/bin/bash

# Create a new directory
echo "Creating a new directory..."
mkdir -p test_directory

# Create a file inside the directory
echo "Creating a new file..."
touch test_directory/sample.txt

# Write some content to the file
echo "Hello, this is a test file!" > test_directory/sample.txt

echo "Done! Directory and file created successfully."

# List the contents to verify
ls -l test_directory