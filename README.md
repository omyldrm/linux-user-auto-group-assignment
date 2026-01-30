# linux-user-auto-group-assignment
Bash script that creates Linux users and automatically assigns them to the smallest group.

## Description

The script:
- Creates a new user account
- Automatically assigns the user to `group1` or `group2`
- Balances group membership
- Generates a temporary password
- Forces password change on first login
- Logs user creation details securely

The script must be run with root privileges.

## Usage

Make the script executable: `chmod +x user-create.sh`
Run the script as root: `sudo ./user-create.sh <username>`
Optional flag to hide password output: `sudo ./user-create.sh <username> --no-print-password`

## Technologies Used
  - Bash, Linux, useradd, groupadd, chpasswd, chage


## Notes
  - Root privileges are required
  - Passwords are not logged
  - Users are required to change their password on first login
  - This script is intended for educational purposes
