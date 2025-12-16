# asdf-pnpm

[![Build Status](https://github.com/jonathanmorley/asdf-pnpm/workflows/asdf-pnpm%20CI/badge.svg)](https://github.com/jonathanmorley/asdf-pnpm/actions)

[pnpm][2] plugin for the [asdf][1] version manager.

## Requirements

Supported platforms:

- Macos on ARM
- Linux on x86-64
- Linux on ARM

### Utilities

The following utilities are required:

- `bash`
- `curl`
- `grep`
- `cut`
- `sort`
- `xargs`
- `tar`
- `ln`

## Installing

```
asdf plugin add pnpm
```

or for asdf \<0.16.0:

```
asdf plugin-add pnpm
```

## Testing

Use the following commands to run tests for all supported architectures (`--all-systems` does not appear to work correctly for this):

```
nix flake check --system aarch64-darwin --impure
nix flake check --system aarch64-linux --impure
nix flake check --system x86_64-linux --impure
```

[1]: https://asdf-vm.com/
[2]: https://pnpm.io/
