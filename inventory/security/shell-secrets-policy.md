# Shell Secrets Policy

Shell startup files are intentionally not copied into this inventory.

Files such as .zshrc, .zprofile, .zshenv, aliases, and local shell snippets may contain API keys, tokens, private paths, or other secrets.

Migration must be performed manually after reviewing and sanitizing the source files.
