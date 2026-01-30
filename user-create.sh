#!/bin/bash

# Script to create users and auto-assign them to group1 or group2
# Based on which group has fewer members
# Usage: ./script.sh <username> [--no-print-password]

LOG_FILE="/var/log/user_creation.log"
GROUP1="group1"
GROUP2="group2"

# Check if username is provided
if [ $# -eq 0 ]; then
    echo "Error: No username specified"
    echo "Usage: $0 <username> [--no-print-password]"
    exit 1
fi

USERNAME="$1"
NO_PRINT=0

# Optional flag
if [ "$2" = "--no-print-password" ]; then
    NO_PRINT=1
fi

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root or with sudo"
    exit 1
fi

# Check if user already exists in /etc/passwd
if grep -q "^$USERNAME:" /etc/passwd; then
    echo "Error: User '$USERNAME' already exists"
    exit 1
fi

# Create groups if they don't exist
if ! grep -q "^$GROUP1:" /etc/group; then
    groupadd "$GROUP1"
    echo "Created group: $GROUP1"
fi

if ! grep -q "^$GROUP2:" /etc/group; then
    groupadd "$GROUP2"
    echo "Created group: $GROUP2"
fi

# Get group information from /etc/group
# Format: groupname:x:gid:member1,member2,member3
group1_line=$(grep "^$GROUP1:" /etc/group)
group2_line=$(grep "^$GROUP2:" /etc/group)

# Extract member list (4th field after last colon)
group1_members=$(echo "$group1_line" | cut -d: -f4)
group2_members=$(echo "$group2_line" | cut -d: -f4)

# Count members (count commas + 1, or 0 if empty)
if [ -z "$group1_members" ]; then
    group1_count=0
else
    group1_count=$(echo "$group1_members" | tr ',' '\n' | wc -l)
fi

if [ -z "$group2_members" ]; then
    group2_count=0
else
    group2_count=$(echo "$group2_members" | tr ',' '\n' | wc -l)
fi

# Determine which group to assign
if [ "$group1_count" -le "$group2_count" ]; then
    ASSIGNED_GROUP="$GROUP1"
else
    ASSIGNED_GROUP="$GROUP2"
fi

echo "Group members count:"
echo "  $GROUP1: $group1_count members"
echo "  $GROUP2: $group2_count members"
echo "Assigning user to: $ASSIGNED_GROUP"
echo ""

# Generate random password
PASSWORD=$(openssl rand -base64 6)

# Create user with the assigned group
useradd -m -g "$ASSIGNED_GROUP" "$USERNAME"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create user"
    exit 1
fi

# Set the password
echo "$USERNAME:$PASSWORD" | chpasswd

if [ $? -ne 0 ]; then
    echo "Error: Failed to set password"
    exit 1
fi

# Force password change on first login (good practice)
chage -d 0 "$USERNAME" 2>/dev/null

# Ensure log file exists and is protected
touch "$LOG_FILE" 2>/dev/null
chmod 600 "$LOG_FILE" 2>/dev/null

# Log the user creation details (NO plaintext password)
echo "=== User Creation - $(date) ===" >> "$LOG_FILE"
echo "Username: $USERNAME" >> "$LOG_FILE"
echo "Group: $ASSIGNED_GROUP" >> "$LOG_FILE"
echo "Password: (generated; must be changed on first login)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Display success message
echo "User created successfully!"
echo "Username: $USERNAME"
echo "Group: $ASSIGNED_GROUP"

if [ "$NO_PRINT" -eq 0 ]; then
    echo "Temporary password: $PASSWORD"
else
    echo "Temporary password: (not displayed)"
fi

echo "User will be asked to change password at first login."
echo ""
echo "Details saved to: $LOG_FILE"
