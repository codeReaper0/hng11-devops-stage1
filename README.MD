README: User Management Script By Tella Boluwatife

Overview
This sh script automates the creation of users, assigns them to groups, sets up home directories, generates random passwords, logs actions, and stores passwords securely. The script reads a text file containing usernames and groups, where each line is formatted as user;groups.

Prerequisites
Root privileges to manage user accounts and groups.
A text file containing usernames and groups, with each line formatted as user;groups.
Usage
Ensure the script is executable(I already did, but in case):

chmod +x create_users.sh
Run the script with the text file as an argument:

sudo ./create_users.sh <name-of-text-file>
Example Text File
text
Copy code
light; sudo,dev,www-data
idimma; sudo
mayowa; dev,www-data

Script Explanation
Check for Root Privileges:

if [ "$EUID" -ne 0 ]; then
echo "Please run as root"
exit 1
fi
Define Log and Password File Paths:

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
Create Secure Directory:

mkdir -p /var/secure
chmod 700 /var/secure
Validate Input File:

if [ -z "$1" ]; then
echo "Usage: $0 <name-of-text-file>"
exit 1
fi

if [ ! -f "$1" ]; then
echo "File $1 does not exist."
exit 1
fi

Utility Functions:

generate*password() {
< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&\*()-*=+' | head -c 12
}

log_action() {
echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

Main Logic:

while IFS=';' read -r username groups; do
username=$(echo "$username" | xargs)
groups=$(echo "$groups" | xargs)

if id "$username" &>/dev/null; then
log_action "User $username already exists."
continue
fi

useradd -m "$username"
if [ $? -eq 0 ]; then
log_action "User $username created successfully."
else
log_action "Failed to create user $username."
continue
fi

usermod -g "$username" "$username"

if [ -n "$groups" ]; then
IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
group=$(echo "$group" | xargs)
if ! getent group "$group" >/dev/null; then
        groupadd "$group"
log_action "Group $group created."
      fi
      usermod -aG "$group" "$username"
log_action "User $username added to group $group."
done
fi

password=$(generate_password)
  echo "$username:$password" | chpasswd
log_action "Password for user $username set."

echo "$username,$password" >> "$PASSWORD_FILE"
done < "$1"

chmod 600 "$PASSWORD_FILE"

log_action "Script execution completed."

echo "User creation process completed. Check $LOG_FILE for details."
