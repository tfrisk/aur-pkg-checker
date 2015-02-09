#!/usr/bin/env ruby
#
# Test suite for aur-pkg-checker.rb
#
# (C) 2015 Teemu Frisk
# Distributed under MIT License

require_relative 'aur-pkg-checker'
require 'minitest/autorun'

class TestAurPackageChecker < Minitest::Test
  def setup
    @checker = AurPackageChecker.new
  end

  def test_version_comparisons
    assert_equal @checker.compare_versions('1.00.27.04-1','1.00.29-3'), -1
    assert_equal @checker.compare_versions('0.4.6-10', '0.4.6-10'), 0
    assert_equal @checker.compare_versions('1.99.alpha1-3', '1.99.alpha1-2'), 1
  end

  def test_output_header
    assert_match /#{Time.now.year}/, @checker.print_output_header()
  end

  def test_output_row_printing
    # do not test the actual strings because they might change during development
    # just make sure there are important keywords
    status = {name: "foo", current: "1.0.1", latest: "1.0.1", comparison: 0}
    assert_match /OK/, @checker.make_output_row(status)

    status = {name: "foo", current: "1.0.1", latest: "1.2.1", comparison: -1}
    assert_match /new version/, @checker.make_output_row(status)

    status = {name: "foo", current: "1.2.1", latest: "1.0.1", comparison: 1}
    assert_match /newer/, @checker.make_output_row(status)
  end
end
