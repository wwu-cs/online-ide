## The cpp Workspace

This workspace contains commonly used tools for C/C++ debugging, including:
- latest clangd-8 Language Server (nightly build)
- latest stand-alone clang-tidy static analyser (nightly build)
- GDB 8.1 (from Ubuntu repo)
- cmake 3.10.2 (from Ubuntu repo)

The included Theia-based IDE application has the following notable features
- [@theia/cpp] Language-server built-in clang-tidy static analyser integration. Will analyse files opened in the IDE's editors and report problems for configured rules. See [README](https://github.com/theia-ide/theia/tree/master/packages/cpp#using-the-clang-tidy-linter) for more details, including related preferences
- [TODO][@theia/cpp-debug] basic C/C++ debugging support

### How to use

Run on http://localhost:3000 with the current directory as a workspace:

```bash
docker run --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name workspaceName --hostname code -u uid:100 -e "LDAPUNAME=username" --init -it -p 3000:3000 -v "$(pwd):/home/project:cached" theia-cpp
```

Options:
- `--cap-add=SYS_PTRACE` will enable tracing for gdb debugging
- `--security-opt seccomp=unconfined` enables running without [the default seccomp profile](https://docs.docker.com/engine/security/seccomp/) to allow cpp debugging
- `--name workspaceName` names the workspace for easier reference
- `--hostname code` sets the hostname in the workspace to "code"
- `-u uid:100` runs the container as the user with the provided uid
- `-e "LDAPUNAME=username"` will set the username inside the container to the provided string
- `--init` injects an instance of [tini](https://github.com/krallin/tini) in the container, that will wait-for and reap terminated processes, to avoid leaking PIDs
- `-p 3000:3000` links the internal port (second 3000) to the external port (first 3000)
- `-v "dir:/home/project:cached` mounts the local director `dir` in the appropriate place in the container
