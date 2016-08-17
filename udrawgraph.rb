require "formula"

class Udrawgraph < Formula
  # version "2014-01-06"
  homepage 'http://www.informatik.uni-bremen.de/uDrawGraph/en/uDrawGraph/uDrawGraph.html'
  url "http://www.informatik.uni-bremen.de/uDrawGraph/download/uDrawGraph-3.1.1-5-macosx-i386.tar.gz"
  version "3.1.1-5"
  sha256 '88a1b982b27dca5aa6640741e43c99535f7ffdb1b96c92a744fd04f6ddff8f35'

  def install
    inreplace 'bin/.uDrawGraph-wrapper' do |s|
      s.sub! 'UDG_HOME=`dirname "$0"`/..', 'UDG_HOME=/usr/local/opt/udrawgraph/'
    end
    prefix.install Dir['*']
    system("rm -f #{bin.join('wish')}")
  end

  def caveats
  end
end
