# xcclean

Helps you to recover disk space from Xcode. Based on [this blog post](https://blog.neverthesamecolor.net/how-to-recover-disk-space-from-xcode/).

# Synopis

```
xcclean [derived_data|device_support|archives|simulators|documentation] [show|delete|delete_all]
```

# Description

`xcclean` displays disk usage for various sets of data Xcode accumulates over time. This data can be deleted by `xcclean` as well.

## Installing xcclean

The recommended way of installing `xcclean` is via Homebrew.

```
brew install xcclean
```

Alternatively, the source code can be downloaded and compiled manually.

## Options

`derived_data`

Data about projects which includes index, build output and logs. 

`device_support`

Information about devices that have been used for development. Will be recreated by Xcode when a device is attached.

`archives`

Archives of release builds. Should be treated with care to not delete archives for which the dSYM data for debugging is still needed.

`simulators`

Simulators are stored in different folders per device and iOS version.

`documentation`

DocSets downloaded by Xcode.

### Available Actions

`show`

Displays a list of folders with their disk usage prefixed. Will contain additional detail information for the cases of `device_support` and `simulators` to make identification of the data easier.

`delete`

Deletes the specified directory. Expects to be followed by the directory name displayed in the second column of the `show` command.

`delete_all`

Deletes **all** directories for specified option.

#### Examples

Show all directories containing derived data:

```
xcclean derived_data show
```

Delete a specific derived data directory:

```
xcclean derived_data delete 0359B714-8C54-4A9B-8EDE-1D6ACB686B59
```

Delete all derived data:

```
xcclean derived_data delete_all
```

# About

* Author: Sascha M Holesch <[https://github.com/hectique]()>
* Issue tracker: This project's source code and issue tracker can be found at [https://github.com/hectique/xcclean]()