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
def get_installed_pkg_list()
  pkg_list = Hash.new() # init new hash
  # run pacman command and add results to hash
  pacman_output = %x[pacman -Qm].split(/[\n]/)
  pacman_output.each do |pkg|
    name,version = pkg.split
    pkg_list[name] = version
  end
  pkg_list
end

# read installed packages
installed_pkg_list = get_installed_pkg_list

# get package info from its AUR page:
# https://aur.archlinux.org/packages/blueman/
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

print "Current time is #{Time.now}\n"
print "Checking package versions\n"
installed_pkg_list.each do |name, current_version|
  latest_version = get_latest_pkg_version(get_pkg_info(name))

  print name + ": " + current_version

  # use pacmans own vercmp tool to check the versions
  cstatus = %x[vercmp #{current_version} #{latest_version}].to_i
  if cstatus == 0 # current = latest
    print " => OK\n"
  elsif cstatus < 0 # current < latest
    print " => new version available: #{latest_version}\n"
  elsif cstatus > 0 # current > latest
    print " => newer version installed: #{latest_version}"
  end
end
