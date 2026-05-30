# Homebrew Tap for Spectranext

Homebrew formulas for Spectranext tools.

## Install

```bash
brew tap spectranext/homebrew-spectranext
brew install spectranext-sdk
```

## Setup

Load the SDK environment in your shell:

```bash
source "$(brew --prefix spectranext-sdk)/libexec/source.sh"
```

Or add it to your shell profile:

```bash
echo 'source "$(brew --prefix spectranext-sdk)/libexec/source.sh"' >> ~/.zshrc
```

## Projects

Configure CMake projects with the z88dk toolchain:

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$(brew --prefix spectranext-sdk)/libexec/z88dk/support/cmake/Toolchain-zcc.cmake"
```

## Upgrade

```bash
brew update
brew upgrade spectranext-sdk
```

## Uninstall

```bash
brew uninstall spectranext-sdk
brew untap spectranext/homebrew-spectranext
```
