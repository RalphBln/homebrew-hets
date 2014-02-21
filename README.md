# homebrew-hets

This is an attempt to create usuable homebrew formulas for hets (the [heterogeneous toolset][1])
for the developers of [ontohub][2] who use Mac OS X as their development platform.

I hope this helps...

## Instructions

In order to use this tap you'll need to perform some basic command-line tasks:

- `brew tap 0robustus1/hets` to make this tap available to your homebrew installation


### hets

We currently supply hets in two different versions:

  - `hets-binary`, which is based on a dmg-Image which is updated
    with the latest binary if requested. This only supports
    *Mac OS X 10.9 (Mavericks)* and up.
  - `hets` which builds a current version (in which current is based on
    the needs of the [ontohub-team][2]). It also
    supports building the current HEAD revision of the repository.

#### Build

  - `brew install hets --with-wrapper` will build and install the
    current version of hets including a wrapper script, which
    will run hets with the correct environment variables set.
  - If you want to install the HEAD (the most *bleeding-edge*)
    version of hets, just add the `--HEAD` switch, like this:
    `brew install hets --HEAD --with-wrapper`.
  - If you don't want or need the wrapper script, you can
    omit the `--with-wrapper` switch.

#### Binary

  - `brew install hets-binary --with-nightly` to install the most recent version of hets

Installing hets will fetch the most recent version of hets known to this
formula, but adding the `--with-nightly` switch will also fetch the
most recent nightly build (always) and update your hets-binary with it.

We also have the `hets-update` script which will allow you to manually update the hets binary
to the latest nightly build. It will be installed by either providing the `--with-nightly`
or the `--with-updater` switch.

[1]: http://www.informatik.uni-bremen.de/agbkb/forschung/formal_methods/CoFI/hets/index_e.htm
[2]: https://github.com/ontohub/ontohub
