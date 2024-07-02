#!/bin/bash

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Log file
LOG_FILE="/var/log/user_management.log"
# Password file
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure the secure directory exists and set appropriate permissions
mkdir -p /var/secure
chmod 700 /var/secure

# Check if the file argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1
fi

# Check if the input file exists
if [ ! -f "$1" ]; then
  echo "File $1 does not exist."
  exit 1
fi

# Function to generate a random password
generate_password() {
  < /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' | head -c 12
}

# Function to log actions
log_action() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Read the input file and process each line
while IFS=';' read -r username groups; do
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs) 

  if id "$username" &>/dev/null; then
    log_action "User $username already exists."
    continue
  fi

  # Create the user with a home directory
  useradd -m "$username"
  if [ $? -eq 0 ]; then
    log_action "User $username created successfully."
  else
    log_action "Failed to create user $username."
    continue
  fi

  # Set the user's primary group to their own username
  usermod -g "$username" "$username"

  # Assign additional groups
  if [ -n "$groups" ]; then
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
      group=$(echo "$group" | xargs) # Trim whitespaces
      if ! getent group "$group" >/dev/null; then
        groupadd "$group"
        log_action "Group $group created."
      fi
      usermod -aG "$group" "$username"
      log_action "User $username added to group $group."
    done
  fi

  # Generate a password
  password=$(generate_password)
  echo "$username:$password" | chpasswd
  log_action "Password for user $username set."

  # Store the password in the secure file
  echo "$username,$password" >> "$PASSWORD_FILE"
done < "$1"

# Set the appropriate permissions for the password file
chmod 600 "$PASSWORD_FILE"

log_action "Script execution completed."

echo "User creation process completed. Check $LOG_FILE for details."
