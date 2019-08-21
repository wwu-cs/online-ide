#!/bin/bash


# change username of given user to match
echo "Changine user$SUDO_UID to $LDAPUNAME"
sed -i 's/user'"$SUDO_UID"'/'"$LDAPUNAME"'/' /etc/passwd

