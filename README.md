# Slow Quit Apps

An OS X app that adds a global delay of 1 second to the Cmd-Q shortcut. In
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
$ brew cask update
$ brew cask reinstall slowquitapps
```

Relaunch the application. Other application instances will be automatically
terminated.

### Compatibility

The app works on Mountain Lion (10.8) and newer.

### Changing default delay

For example, to change the delay to 5 seconds, open up Terminal app and
run the following command:

    $ defaults write com.dteoh.SlowQuitApps delay -int 5000

The delay is specified in milliseconds.

