require "formula"
require 'rexml/document'

class HetsCommons < Formula
  @@version_commit = 'b8488370dfa4f324561bf90f8dd443696317e385'
  @@version_no = '0.99'
  @@version_unix_timestamp = '1472225208'
  homepage "http://hets.eu"
  head "https://github.com/spechub/Hets.git", :using => :git
  url "https://github.com/spechub/Hets.git", :using => :git, :revision => @@version_commit
  version "#{@@version_no}-#{@@version_unix_timestamp}"
  revision 1

  bottle do
    root_url 'http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets'
    revision 1
    sha256 '885379c2bfa13aae813d10d8fbe1ca413d2f9b9316b80b8433db8425f0724477' => :mavericks
    sha256 '885379c2bfa13aae813d10d8fbe1ca413d2f9b9316b80b8433db8425f0724477' => :yosemite
    sha256 '885379c2bfa13aae813d10d8fbe1ca413d2f9b9316b80b8433db8425f0724477' => :el_capitan
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
