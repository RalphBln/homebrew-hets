require "formula"

class HetsLib < Formula
  # Both the version and the sha1 need to be adjusted when a new
  # dmg-version of hets is released.

  @@revision = '3e63c1157440e2ba05dbec6fbcc7f59aa743fc3a'
  homepage 'http://www.informatik.uni-bremen.de/cofi/Libraries/'
  url "https://github.com/spechub/Hets-lib.git", :using => :git, :revision => @@revision
  version "unknown-#{@@revision}"

  def install
    prefix.install Dir['*']
  end

  def caveats
  end

end
