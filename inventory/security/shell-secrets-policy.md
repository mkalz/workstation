# Shell Safety Note

Shell startup files are intentionally not copied into this inventory.

Reason: files such as .zshrc, .zprofile, .zshenv, aliases, and local shell snippets may contain API keys, tokens, private paths, or other secrets.

Migration should be performed manually and only after reviewing and sanitizing the source files.
