# Dotfiles

This repository contains the shell configuration and setup scripts for a cross-platform development environment based on Bash and the Nix package manager.

## Directory Layout

```
shell/
  common/       # Sourced by every login shell, on any OS
  bash/         # Extras for bash only

bootstrap/      # Scripts for setting up a new machine
  packages.apt  # List of packages to install on Debian/Ubuntu
  packages.brew # List of packages to install on macOS
```

## Bootstrapping a New Machine

This setup is designed to be idempotent and can be run on a fresh machine to configure it from scratch.

**Prerequisites:**
* A Debian, Ubuntu, or macOS based system.
* `git` and `curl` must be installed.

**Setup Steps:**

1.  **Clone the required repositories:**

    ```bash
    # Clone the dotfiles repo
    git clone <your-dotfiles-repo-url> ~/dotfiles

    # Clone the Nix configuration repo
    git clone <your-nix-config-repo-url> ~/nix-config
    ```

2.  **Run the master setup script:**

    ```bash
    cd ~/dotfiles
    bash bootstrap/setup-new-machine.sh
    ```

This script will perform all the necessary steps:
*   Install system packages from the `packages.apt` or `packages.brew` lists.
*   Install the Nix package manager if it's not already present.
*   Set up your `~/.bashrc` and `~/.bash_profile`.
*   Run `nix-switch` to deploy all the packages and configurations from your `nix-config` repository.

After the script completes, open a new terminal session to see the effects.

## Managing System Packages

To add or remove system-level packages for `apt` or `brew`, simply edit the `bootstrap/packages.apt` or `bootstrap/packages.brew` files.

To automatically update these lists based on your currently installed packages, you can run the update script from within the `bootstrap` directory:

```bash
cd ~/dotfiles/bootstrap
bash ./update-package-lists.sh
```
