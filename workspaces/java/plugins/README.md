# Plugin Directory

Any VS Code plugins placed in this directory will be copied into the docker image on build.  Those will then
be copied to the user's plugin directory (`~/.theia/plugins`).  Note that users can add plugins to this directory
as well.  Theia will attempt to load any plugin found in this directory when it starts up.

## Java Plugins

As of the initial development of this image, the following plugins are included (although they are not saved in git):

* [java-test](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-test) for visualizing JUnit

The most recent versions should be downloaded into this directory before building the docker image (and subsequently tested).

Other java plugins may be helpful, but this would be a good starting one.
