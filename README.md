# AUR package checker

A command line tool for checking local packages installed from AUR (Arch User Repository).

## Requirements

* Arch Linux
* Ruby programming language runtime

## Usage

The script checks your local installed packages (with <code>pacman -Qm</code>) and then performs a check againts the latest versions in AUR (https://aur.archlinux.org/). The version comparison is done with <code>vercmp</code> which guarantees compatibility with <code>pacman</code>.

Example:
<pre>
$ ruby aur-pkg-checker.rb
Current time is 2015-02-11 11:49:07 +0200
Checking package versions
libudev.so.0: 0.1.1-2 => OK
lighttable: 0.7.2-1 => OK
sublime-text: 2.0.2-1 => new version available: 2.0.2-4
</pre>

In this example the user has 3 installed packages. Two of these packages are up-to-date, and one has a newer version available.

The script can be run with regular user privileges.

## TODO

* Command line option parsing
* Download new package files
* Log actions
* Ignored package list (don't want to update certain packages)
* Install new packages


Copyright (C) 2015 Teemu Frisk
Distributed under MIT License
