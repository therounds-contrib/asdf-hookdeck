# Contributing

Testing locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

# E.g., to test the currently-released version:
asdf plugin test hookdeck https://github.com/therounds-contrib/asdf-hookdeck.git "hookdeck version"

# Or to test against a local commit:
asdf plugin test hookdeck ./.git --asdf-tool-version 0.6.7 --asdf-plugin-gitref main "hookdeck version"
```

Tests are automatically run in GitHub Actions on push and PR.
