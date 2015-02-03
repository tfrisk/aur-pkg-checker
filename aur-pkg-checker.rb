#!/usr/bin/env ruby
#
# Arch Linux user repository version checking tool
# This is a simple tool that just checks if you have all the
# latest packages from AUR. See https://aur.archlinux.org/
# for more information about AUR.
#
# (C) 2015 Teemu Frisk
# Distributed under MIT License

require 'net/http' # use net/http because it's in ruby std libs

# list of installed packages
# hash with pkg names as keys and versions as values
# TODO: get the actual list from pacman (Arch Linux package manager)
installed_pkg_list = Hash[
  "blueman"                 => "1.99.alpha1-2",
  "sublime-text"            => "2.0.2-3",
]

# PKGBUILD file path example:
# https://aur.archlinux.org/packages/ # this gets the index page
def get_pkg_info(pkgname)
  Net::HTTP.get(
    URI.parse("https://aur.archlinux.org/packages/" + pkgname))
end

# parse html source, version line example:
# <h2>Package Details: blueman 1.99.alpha1-2</h2>
# this current implementation is probably too fragile for production use
def get_latest_pkg_version(infocontent)
  # first get the relevant file with regex
  versionline = /^.*Package Details:.*$/.match(infocontent)[0]
  # then use split to extract the version info
  versionline.split(/[\s,<]/)[5]
end

print "Checking latest versions\n"
installed_pkg_list.each do |name, current_version|
  latest_version = get_latest_pkg_version(get_pkg_info(name))

  print name + ": " + current_version
  if current_version >= latest_version
    print " => up to date, OK\n"
  else
    print " => new version available: #{latest_version}\n"
  end
end
