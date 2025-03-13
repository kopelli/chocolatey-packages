# chocolatey-packages
Kopelli's automatic chocolatey packages using AU

** Inspired by https://github.com/AdmiringWorm/chocolatey-packages and https://github.com/chocolatey-community/chocolatey-packages-template, but does not necessarily follow same conventions

# Initial setup

Run `git config --local core.hooksPath "$(Join-Path -Path $(git rev-parse --show-toplevel) -ChildPath .githooks)"`