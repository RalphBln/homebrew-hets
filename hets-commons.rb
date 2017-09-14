require "formula"
require 'rexml/document'

class HetsCommons < Formula
  @@version_commit = '430ab7208b425d007aa2d7e035eb0a3329da20bc'
  @@version = '0.100.0'
  homepage 'http://hets.eu'
  head 'https://github.com/spechub/Hets.git', :using => :git
  url 'https://github.com/spechub/Hets.git', :using => :git, :revision => @@version_commit
  version @@version
  revision 1

  bottle do
    root_url 'http://hets.eu/downloads/hets/macOS'
    sha256 'f6fc9514c7d19adbec0a99715fe30b7fb4627d809fee6ef8c7d14d5740900de2' => :mavericks
    sha256 'f6fc9514c7d19adbec0a99715fe30b7fb4627d809fee6ef8c7d14d5740900de2' => :yosemite
    sha256 'f6fc9514c7d19adbec0a99715fe30b7fb4627d809fee6ef8c7d14d5740900de2' => :el_capitan
    sha256 'f6fc9514c7d19adbec0a99715fe30b7fb4627d809fee6ef8c7d14d5740900de2' => :sierra
    sha256 'f6fc9514c7d19adbec0a99715fe30b7fb4627d809fee6ef8c7d14d5740900de2' => :high_sierra
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
