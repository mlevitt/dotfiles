## Yet another dotfile repository ##

    $  git clone https://github.com/DeeNewcum/dotfiles.git
    $  cd dotfiles
    $  ./setup.pl
    $  ls -l ~/.bashrc
    ~/.bashrc -> ~/dotfiles/.bashrc

    # Your dotfiles are safe.  Setup.pl won't overwrite anything.

## Overview ##

Run setup.pl, fix the file conflicts that it notes, run setup.pl...   repeat until it doesn't report any conflicts.

Setup.pl recognizes three different ways to incorporate ~/dotfiles/ settings into the working versions:

* **Symlink** — The most common way. For example: ~/.bashrc → ~/dotfiles/.bashrc

* **Source** — Some file types can source another file.  For example:  ~/.bashrc could include the line:

        [ -f ~/dotfiles/.bashrc ] && source ~/dotfiles/.bashrc

* **Text substitution** — Setup.pl will read the text from ~/dotfiles/.gitconfig.subst, and copy-n-paste it into the middle of the ~/.gitconfig file.
  
## Machine-specific overrides — via source ##

In some cases, I want to have local settings, specific to a machine, that override the global repository settings.

For files that allow for 'source' or '#include' functionality, this is possible.  For example, ~/.bashrc can be a real file (instead of a symlink), and I can change settings before and after the line that sources ~/dotfiles/.bashrc.

Setup.pl [knows about each file type](https://github.com/DeeNewcum/dotfiles/blob/b3510c3a0bfedf2f33085a7eeacfa6586730b1f1/setup.pl#L124-131), and will suggest the appropriate 'source' line, whenever it notices an existing local file that conflicts.

You need to manually insert the 'source' line, because order usually matters.  Often, you want your local settings to come after the 'source' line, to override them, but it depends on file type.

## Machine-specific overrides — via text substitution ##

For files that don't allow for 'source', setup.pl will copy-n-paste the contents of, for example, ~/dotfiles/.gitconfig.subst into ~/.gitconfig.

Because order often matters, you again need to manually insert a line that indicates where the global configuration text should be inserted.  Setup.pl will tell you what text to insert.

The text is only substituted when setup.pl is run.  Therefore, to change the text inside the substitution region, you need to modify the ~/dotfiles/ version, and run setup.pl every time you want to test out your change.

## Shared root ##

I manage boxes where several people have access to root.  To avoid stepping on each other other's toes, I have [set up root's ~/.bashrc](https://github.com/DeeNewcum/dotfiles/blob/master/.sudo_bashrc#L3-5) so that it loads a ~/.sudo_bashrc from the [original user's](http://paperlined.org/apps/host_sudo_su_boundaries/user_ids.html) home directory.

My own ~/.sudo_bashrc will pull in a variety of other .rc settings from the original home directory, including ~/.vimrc, ~/.inputrc, ~/.less, ~/.ackrc, and ~/.perltidyrc.

## My background ##

I use 5 unix boxes on a daily basis, so checking in my dotfiles is a must.

I often work in Ubuntu, RHEL, and Solaris.  And that's Solaris 9, on boxes I don't control so I can't install a modern GNU toolset, so there are various tricks here to coerce Solaris 9 to behave in similar ways to modern OS's.

## Similar projects ##

There are a [TON of other people](https://github.com/search?utf8=%E2%9C%93&q=dotfiles&repo=&langOverride=&start_value=1&type=Repositories&language=) who store their dotfiles on github.  Ones that stand out for me:

* [rtomayko](https://github.com/rtomayko/dotfiles)
* [aspiers](https://github.com/aspiers/shell-env)
* [claytron](https://github.com/claytron/dotfiles)
* [sjbach](https://github.com/sjbach/env)
* [mathiasbynens](https://github.com/mathiasbynens/dotfiles/)
* [yuzuemon](https://github.com/yuzuemon/dotfiles)
* [skwp](https://github.com/skwp/dotfiles)
* [ryanb](https://github.com/ryanb/dotfiles)
* [blueyed](https://github.com/blueyed/dotfiles)
* [phleet](https://github.com/phleet/dotfiles)
* [zan5hin](https://github.com/zan5hin/dotfiles)
* [nelstrom](https://github.com/nelstrom/dotfiles)
* [sontek](https://github.com/sontek/dotfiles)
* [sharad](https://github.com/sharad/rc) (uses m4 to customize files that have no 'source' capability)

## License ##

Unless otherwise noted, files here are available under the [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) license.

Some files (particularly ones authored by other folks) may have their own licensing information at the top of the file.  Those notices supercede this one.
