<div align="center">

# asdf-hookdeck [![Build](https://github.com/therounds-contrib/asdf-hookdeck/actions/workflows/build.yml/badge.svg)](https://github.com/therounds-contrib/asdf-hookdeck/actions/workflows/build.yml) [![Lint](https://github.com/therounds-contrib/asdf-hookdeck/actions/workflows/lint.yml/badge.svg)](https://github.com/therounds-contrib/asdf-hookdeck/actions/workflows/lint.yml)


[hookdeck](https://hookdeck.com/cli) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

This plugin depends on common POSIX utilities (`awk`, `head`, `grep`, `sed`,
`tar`, etc.), Bash, curl, and Git. Ideally all stuff you had to have installed
to get asdf working in the first place.

# Install

Plugin:

```shell
asdf plugin add hookdeck
# or
asdf plugin add hookdeck https://github.com/therounds-contrib/asdf-hookdeck.git
```

hookdeck:

```shell
# Show all installable versions
asdf list-all hookdeck

# Install specific version
asdf install hookdeck latest

# Set a version globally (on your ~/.tool-versions file)
asdf global hookdeck latest

# Now hookdeck commands are available
hookdeck version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/therounds-contrib/asdf-hookdeck/graphs/contributors)!

# License

See [LICENSE](LICENSE).

Copyright © 2023 [Boondoc Technologies Inc.](https://therounds.com/)
