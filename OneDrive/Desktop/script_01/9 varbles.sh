#!/bin/bash
# simple interactive script with defaults

read -p "Name [Ayush]: " name
name=${name:-Ayush}

read -p "Age [20]: " age
age=${age:-20}

read -p "Pointer [9.89]: " pointer
pointer=${pointer:-9.89}

printf 'Name: %s\nAge: %s\nPointer: %s\n' "$name" "$age" "$pointer"
echo "Now: $(date '+%F %T')"
echo "User: ${USER:-$(whoami)}"
echo "Shell: ${SHELL:-unknown}"