require "formula"
require 'rexml/document'

class HetsCommons < Formula
  @@version_commit = '9c020bf240dace07c6defccb1c8a42328ec454e0'
  @@version_no = '0.99'
  @@version_unix_timestamp = '1471209385'
  homepage "http://hets.eu"
  head "https://github.com/spechub/Hets.git", :using => :git
  url "https://github.com/spechub/Hets.git", :using => :git, :revision => @@version_commit
  version "#{@@version_no}-#{@@version_unix_timestamp}"

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
    FileUtils.ln_sf(HOMEBREW_PREFIX.join('opt', 'pellet', 'bin').to_s,
                    share.join('pellet').to_s)
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
