#!/bin/bash

# set the base url and project ID
BASE="https://gitlab.cs.wallawalla.edu"
PID="cptr141%2Fstudent141"

# generate an ssh public/private key pair if it doesn't exist
if [ ! -e "/home/project/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -N "" -f /home/project/.ssh/id_rsa > /dev/null
fi

# grab the contents
SSHKEY=$(cat /home/project/.ssh/id_rsa.pub)

# prompt for username and password
read -p 'Username: ' USERVAR
read -sp 'Password: ' PASSVAR
echo

# attempt to login to gitlab
RESPONSE=$(curl -s --data "grant_type=password&username=$USERVAR&password=$PASSVAR" --request POST $BASE/oauth/token)

# parse output to see if valid login
TOKEN=$(echo $RESPONSE | python -c "import sys,json; print(json.load(sys.stdin).get('access_token','x'))")
if [ "$TOKEN" == "x" ]; then
  echo "Invliad Login"
  exit
fi

# if it was valid, deploy the SSH key (no error checking for now)
RESPONSE=$(curl -s --data-urlencode "key=$SSHKEY" --data-urlencode "title=Code.CS Key" --request POST $BASE/api/v4/user/keys?access_token=$TOKEN)

# fork the repository
RESPONSE=$(curl -s --request POST $BASE/api/v4/projects/$PID/fork?access_token=$TOKEN)

# now check it out, provided the directory doesn't exist
if [ ! -d "/home/project/code/student141" ]; then
  cd /home/project/code
  git clone git@gitlab.cs.wallawalla.edu:/$USERVAR/student141.git
  cd student141
  git remote add upstream git@gitlab.cs.wallawalla.edu:cptr141/student141.git
fi
