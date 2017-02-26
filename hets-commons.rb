require "formula"
require 'rexml/document'

class HetsCommons < Formula
  @@version_commit = 'b39edff7b191f41fb4b7268e00dd0289965ca9bf'
  @@version_no = '0.99'
  @@version_unix_timestamp = '1484075143'
  homepage "http://hets.eu"
  head "https://github.com/spechub/Hets.git", :using => :git
  url "https://github.com/spechub/Hets.git", :using => :git, :revision => @@version_commit
  version "#{@@version_no}-#{@@version_unix_timestamp}"
  revision 1

  bottle do
    root_url 'http://hets.eu/downloads/hets/macOS'
    revision 1
    sha256 'f930b18598ebc0468dfe2b54163453f7eae007050fa088755c464c1eaa10bcf4' => :mavericks
    sha256 'f930b18598ebc0468dfe2b54163453f7eae007050fa088755c464c1eaa10bcf4' => :yosemite
    sha256 'f930b18598ebc0468dfe2b54163453f7eae007050fa088755c464c1eaa10bcf4' => :el_capitan
    sha256 'f930b18598ebc0468dfe2b54163453f7eae007050fa088755c464c1eaa10bcf4' => :sierra
  end

  depends_on :java => :build
  depends_on 'ant' => :build
  depends_on 'ghc' => :build

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
