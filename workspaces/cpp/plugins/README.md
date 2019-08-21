## Plugin Directory

Any VS Code plugins placed in this directory will be copied into the docker image on build.  Those will then
 be copied to the user's plugin directory (if they don't already have one) and loaded when the container runs.
  As of the initial development of this image, the following plugins are included (although they are not saved in git):

* [code-runner])https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) for easy compilation and running of C/C++ programs
* [webfreak-debugger](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) for rudamentary GDB debugging

The most recent versions should be downloaded into this directory before building the docker image (and subsequently tested).
