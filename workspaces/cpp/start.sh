#!/bin/bash

# test whether plugins directory exists in home filesystem and create it if not
if [ ! -d "/home/project/.theia/plugins" ]; then
  mkdir -p /home/project/.theia/plugins
fi

# test whether code directory exists in home filesystem and create it if not
if [ ! -d "/home/project/code" ]; then
  mkdir -p /home/project/code
fi

# copy system wide plugins to user directory
cp /home/theia/plugins/* /home/project/.theia/plugins

# copy default settings if not overridden
if [ ! -f "/home/project/.theia/settings.json" ]; then
  cp /home/theia/.theia/settings.json /home/project/.theia/
fi

# replace username in passwd file
sudo -E /usr/local/bin/uname_fix.sh

# start backend in new bash shell
node /home/theia/src-gen/backend/main.js /home/project/code --hostname=0.0.0.0

