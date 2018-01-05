require "formula"
require 'rexml/document'

class HetsCommons < Formula
  @@version_commit = 'a389e88e0acb83d8489bdc5e55bc5522b152bbec'
  @@version = '0.100.0'
  homepage 'http://hets.eu'
  head 'https://github.com/spechub/Hets.git', :using => :git
  url 'https://github.com/spechub/Hets.git', :using => :git, :revision => @@version_commit
  version @@version
  revision 1

  bottle do
    root_url 'http://hets.eu/downloads/hets/macOS'
    sha256 'f3f4003548d380b5d591360aa6d20aac0c5949c8ad3f67cd2a4fb95d91ceab6f' => :mavericks
    sha256 'f3f4003548d380b5d591360aa6d20aac0c5949c8ad3f67cd2a4fb95d91ceab6f' => :yosemite
    sha256 'f3f4003548d380b5d591360aa6d20aac0c5949c8ad3f67cd2a4fb95d91ceab6f' => :el_capitan
    sha256 'f3f4003548d380b5d591360aa6d20aac0c5949c8ad3f67cd2a4fb95d91ceab6f' => :sierra
    sha256 'f3f4003548d380b5d591360aa6d20aac0c5949c8ad3f67cd2a4fb95d91ceab6f' => :high_sierra
  end

  depends_on :java => :build
  depends_on 'ant' => :build
  depends_on 'haskell-stack' => :build

  depends_on 'hets-lib'

  def install
    # install_dependencies
    puts "Compiling hets-commons..."
    system(%(make install-common PREFIX="#{prefix}"))
    FileUtils.ln_sf(HOMEBREW_PREFIX.join('opt', 'hets-lib').to_s,
                    lib.join('hets', 'hets-lib').to_s)
  end

  def caveats
    puts 'Building Hets from source requires Java 7 to be installed.'
  end

  protected

  def install_dependencies
    puts 'Installing dependencies...'
    ghc_prefix = `ghc --print-libdir | sed -e 's+/lib.*/.*++g'`.strip
    opts = ['--force-reinstalls','-p', '--global', "--prefix=#{ghc_prefix}"]
    flags = %w(-f server -f -gtkglade -f -uniform)
    system('cabal', 'update')
    system('cabal', 'install', '--only-dependencies', *flags, *opts)
  end
end
