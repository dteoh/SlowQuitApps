# Slow Quit Apps

A macOS app that adds a global delay of 1 second to the Cmd-Q shortcut. In
other words, you have to hold down Cmd-Q for 1 second before an application
will quit.

When the delay is active, an overlay is drawn at the center of the screen.

## Why?

A quick search for 'command q' on Google revealed these insights:

* "have you ever accidentally hit ⌘Q and quit an app"
* "how to disable command-Q"
* "Command-Q is the worst keyboard shortcut ever"
* "ever hit Command-Q instead of Command-W and lost all of your open web pages in Safari?"

... and many more similar sentiments.

Some proposed solutions include:

* remapping Cmd-Q to do something else
* changing the application quit keyboard short to use another keybinding

This app implements the same approach as Google Chrome's "Warn Before Quitting"
feature, except it is now available on every app!

## Download & Install

Pre-built binaries can be downloaded from the [releases page](https://github.com/dteoh/SlowQuitApps/releases).

Unzip, drag the app to Applications, and then run it. You can optionally
choose to automatically start the application on login.

### Homebrew

If you wish to install the application from Homebrew:

```
$ brew tap dteoh/sqa
$ brew cask install slowquitapps
```

The application will live at `/Applications/SlowQuitApps.app`.

Updating the app:

```
$ brew update
$ brew cask reinstall slowquitapps
$ killall SlowQuitApps
```

Then relaunch the application.

Or using [brew-cask-upgrade](https://github.com/buo/homebrew-cask-upgrade):

```
$ brew cu slowquitapps
```

### Compatibility

The app is currently developed on Mojave and only support for Mojave can be
provided.

* Mavericks (10.9) to High Sierra (10.13) support: please download version 0.5.0
* Mountain Lion (10.8) support: please download version 0.4.0

## Customization

You must exit and relaunch SlowQuitApps after making customizations.

To exit the app:

```
$ killall SlowQuitApps
```

### Changing default delay

The currently set delay can be reviewed with:

    $ defaults read com.dteoh.SlowQuitApps

To change the delay to 5 seconds for example, open up Terminal app and
run the following command:

    $ defaults write com.dteoh.SlowQuitApps delay -int 5000

The delay is specified in milliseconds.

### Whitelisting applications

Whitelisted apps will be sent the Cmd-Q keypress directly.

To whitelist an app, start by locating its bundle ID. For example, to whitelist
the "Notes" application:

    $ osascript -e 'id of app "Notes"'
    com.apple.Notes
    $ defaults write com.dteoh.SlowQuitApps whitelist -array-add com.apple.Notes

To reset the whitelist:

    $ defaults delete com.dteoh.SlowQuitApps whitelist

To check whitelisted apps:

    $ defaults read com.dteoh.SlowQuitApps whitelist

#### Blacklist mode

The whitelist can be used to only allow SlowQuitApps to handle Cmd-Q for those
selected applications. To switch on this mode:

    $ defaults write com.dteoh.SlowQuitApps invertList -bool YES

In this mode, non-whitelisted apps will be sent the Cmd-Q keypress directly.

To switch off this mode:

    $ defaults delete com.dteoh.SlowQuitApps invertList

### Hide overlay

By default, an overlay with an indicator of the time remaining until the app gets closed appears. To hide this overlay, run the following command:

    $ defaults write com.dteoh.SlowQuitApps displayOverlay -bool NO

## License

```
SlowQuitApps

Copyright (C) 2019 Douglas Teoh

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
```

### App Icon

The app icon is a contribution courtesy of @fancyme (#35).
