# chocolatey-packages
Kopelli's automatic chocolatey packages using AU

** Inspired by https://github.com/AdmiringWorm/chocolatey-packages and https://github.com/chocolatey-community/chocolatey-packages-template, but does not necessarily follow same conventions

# Initial setup

Run `git config --local core.hooksPath "$(Join-Path -Path $(git rev-parse --show-toplevel) -ChildPath .githooks)"`
Run `git config --local core.whitespace tabwidth=2,blank-at-eol,blank-at-eof,-indent-with-non-tab,-tab-in-indent,cr-at-eol`