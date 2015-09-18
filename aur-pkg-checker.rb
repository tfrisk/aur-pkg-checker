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
require 'optparse' # command line option parser

class AurPackageChecker
  @@aur_base_url = "https://aur.archlinux.org/packages/"
  @@tmpdir = Dir.pwd + "/build/"

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

  # get package info from its AUR page:
  # https://aur.archlinux.org/packages/blueman/
  def download_pkg_info(pkgname)
    Net::HTTP.get(
      URI.parse(@@aur_base_url + pkgname))
  end

  # get package tarball from its AUR page:
  # https://aur.archlinux.org/packages/bl/blueman/blueman.tar.gz
  def download_pkg_tarball(pkgname)
    uri = @@aur_base_url +
        pkgname[0..1] + "/" +
        pkgname + "/" +
        pkgname + ".tar.gz"
    print "Downloading " + uri
    res = Net::HTTP.get_response(URI.parse(uri))
    if res.is_a?(Net::HTTPSuccess)
      verify_tmpdir()
      open(@@tmpdir + pkgname + ".tar.gz", "wb") do |file|
        file.write(res.body)
      end
      print "..OK\n"
    else
      print "..Failed!\n"
    end
  end

  # create tmpdir if required
  def verify_tmpdir()
    if !Dir.exists?(@@tmpdir)
      %x[mkdir #{@@tmpdir}]
    end
  end

  # parse html source, version line example:
  # <h2>Package Details: blueman 1.99.alpha1-2</h2>
  # this current implementation is probably too fragile for production use
  def get_latest_pkg_version(infocontent)
    # first get the relevant file with regex
    begin
      versionline = /^.*Package Details:.*$/.match(infocontent)[0]
      # then use split to extract the version info
      versionline.split(/[\s,<]/)[5]
    rescue
      "PACKAGE NOT FOUND!\n"
    end
  end

  # use pacmans own vercmp tool to check the versions
  def compare_versions(current, latest)
    %x[vercmp #{current} #{latest}].to_i
  end

  def print_output_header()
    header = "Current time is #{Time.now}\n" +
            "Checking package versions\n"
    return header
  end

  def make_output_row(status)
    line = status[:name] + ": " + status[:current]
    if status[:comparison] == 0 # current = latest
      line += " => OK\n"
    elsif status[:comparison] < 0 # current < latest
      line += " => new version available: #{status[:latest]}\n"
    elsif status[:comparison] > 0 # current > latest
      line += " => newer version installed: #{status[:latest]}"
    end
    return line
  end

  # iterate given list
  def iterate_list(pkglist)
    checked_list = {}
    pkglist.each do |name, current_version|
      status = {}
      status[:name] = name
      status[:current] = current_version
      status[:latest] = get_latest_pkg_version(download_pkg_info(name))
      status[:comparison] = compare_versions(status[:current], status[:latest])

      print make_output_row(status)
      checked_list[name] = status
    end
    return checked_list
  end
end

if $0 == __FILE__ # guard class execution for test suite
  # command line parser config
  options = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: aur-pkg-checker.rb [options]"
    opts.on('-h', '--help', 'Display help') do
      puts opts
      exit
    end
    opts.on('-c', '--check-only', 'Check only, do not download') do
      options[:check_only] = true
    end
  end
  # parse command line, catch InvalidOption
  begin parser.parse(ARGV)
  rescue OptionParser::InvalidOption => e
    puts e
    puts parser
    exit 1
  end

  checker = AurPackageChecker.new

  # read installed packages
  installed_pkg_list = checker.get_installed_pkg_list

  print checker.print_output_header()
  checked_list = checker.iterate_list(installed_pkg_list)
  print "Checking completed.\n"

  # download updated packages unless check-only mode
  if (!options[:check_only])
    print "Downloading updated packages..\n"
    checked_list.each do |name, details|
      if (details[:comparison] == -1)
        checker.download_pkg_tarball(name)
      end
    end
  end
end
