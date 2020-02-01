require "formula"

class Factplusplus < Formula
  @@version_commit = '2322e8c27906cb829f36464dee24ec69cea132c4'
  the_version = '1.6.5'
  homepage 'http://owl.man.ac.uk/factplusplus/'
  head 'https://bitbucket.org/dtsarkov/factplusplus.git', :using => :git
  url 'https://bitbucket.org/dtsarkov/factplusplus.git', :using => :git, :revision => @@version_commit
  version the_version

  bottle do
    root_url 'http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets'
    rebuild 1
    sha256 '9690cf3031affe7f8d2b01246534302e26b1634ed60edbd82652ef64c9f5301d' => :mavericks
    sha256 '9690cf3031affe7f8d2b01246534302e26b1634ed60edbd82652ef64c9f5301d' => :yosemite
    sha256 '9690cf3031affe7f8d2b01246534302e26b1634ed60edbd82652ef64c9f5301d' => :el_capitan
    sha256 '9690cf3031affe7f8d2b01246534302e26b1634ed60edbd82652ef64c9f5301d' => :sierra
    sha256 '9690cf3031affe7f8d2b01246534302e26b1634ed60edbd82652ef64c9f5301d' => :high_sierra
  end

  depends_on :java
  depends_on 'gcc' => :build

  def install
    system('make')
    prefix.install('FaCT++.C/obj/libfact.jnilib')
    prefix.install('FaCT++.JNI/obj/libFaCTPlusPlusJNI.jnilib')
  end

  def caveats
  end
end
