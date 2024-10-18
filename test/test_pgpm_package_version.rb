# frozen_string_literal: true

require "test_helper"

class TestPgpmPackageVersion < Minitest::Test
  def test_converts_to_string
    assert_equal Pgpm::Package::Version.new("1.2.103").to_s, "1.2.103"
  end

  def test_equality_with_string
    assert_equal Pgpm::Package::Version.new("1.2.103"), "1.2.103"
  end

  def test_hashes
    assert_equal ({ Pgpm::Package::Version.new("1.2.103") => "yes" }[Pgpm::Package::Version.new("1.2.103")]), "yes"
  end

  def test_compares
    assert Pgpm::Package::Version.new("1.2.103") > Pgpm::Package::Version.new("1.2.3")
  end
end
