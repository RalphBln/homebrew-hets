require "formula"
require 'rexml/document'

class HetsServer < Formula
  @@version_commit = 'a389e88e0acb83d8489bdc5e55bc5522b152bbec'
  @@version = '0.100.0'
  homepage 'http://hets.eu'
  head 'https://github.com/spechub/Hets.git', :using => :git
  url 'https://github.com/spechub/Hets.git', :using => :git, :revision => @@version_commit
  version @@version
  revision 1

  bottle do
    root_url 'http://hets.eu/downloads/hets/macOS'
    sha256 'ccbe20f9a914404b60b6d877a7fd6918724bd8a1d8c297996670c558c9f89db1' => :mavericks
    sha256 'ccbe20f9a914404b60b6d877a7fd6918724bd8a1d8c297996670c558c9f89db1' => :yosemite
    sha256 'ccbe20f9a914404b60b6d877a7fd6918724bd8a1d8c297996670c558c9f89db1' => :el_capitan
    sha256 'ccbe20f9a914404b60b6d877a7fd6918724bd8a1d8c297996670c558c9f89db1' => :sierra
    sha256 'ccbe20f9a914404b60b6d877a7fd6918724bd8a1d8c297996670c558c9f89db1' => :high_sierra
  end

  depends_on 'haskell-stack' => :build
  depends_on 'glib' => :build
  depends_on 'binutils' => :build

  depends_on 'hets-commons'

  depends_on 'darwin' => :recommended
  depends_on 'eprover' => :recommended
  depends_on 'factplusplus' => :recommended
  depends_on 'owltools' => :recommended
  depends_on 'pellet' => :recommended
  depends_on 'spass' => :recommended

  def install
    make_compile_target = 'hets_server.bin'
    make_install_target = 'install-hets_server'
    executable = 'hets-server'
    binary = "hets_server.bin"

    install_dependencies

    puts "Compiling #{executable}..."
    system(%(make #{make_compile_target}))
    system("strip #{binary}")

    puts 'Putting everything together...'
    system(%(make #{make_install_target} PREFIX="#{prefix}"))
    patch_wrapper_script(executable)
  end

  def caveats
  end

  protected

  def install_dependencies
    puts 'Installing dependencies...'
    ghc_prefix = `ghc --print-libdir | sed -e 's+/lib.*/.*++g'`.strip
    opts = ['-p', '--global', "--prefix=#{ghc_prefix}"]
    flags = %w(-f server -f -gtkglade -f -uniform)
    system('cabal', 'update')
    system('cabal', 'install', '--only-dependencies', *flags, *opts)
  end

  # The wrapper script needs to use a shell that is certainly installed.
  # It needs to point to the correct executable.
  # Hets needs to have additional locale settings.
  # It also needs to use the hets-commons package which is located in a
  # different directory.
  def patch_wrapper_script(prog)
		wrapper_script_header = <<-WRAPPER_SCRIPT_HEADER
#!/bin/bash

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

COMMONSDIR="#{HOMEBREW_PREFIX.join('opt', 'hets-commons')}"
PROGDIR="#{prefix}"
PROG="#{prog}"

[[ -z ${HETS_JNI_LIBS} ]] && \\
		        HETS_JNI_LIBS="#{HOMEBREW_PREFIX.join('opt', 'factplusplus')}"
WRAPPER_SCRIPT_HEADER

		# Replace the header until (including) the line starting with PROG=
		inreplace(bin.join(prog), /\A.*PROG=[^\n]*$/m, wrapper_script_header)
    inreplace(bin.join(prog), 'BASEDIR', 'COMMONSDIR')
    inreplace(bin.join(prog), /PELLET_PATH=.*$/, "PELLET_PATH=#{HOMEBREW_PREFIX.join('opt', 'pellet', 'bin')}")
    inreplace(bin.join(prog), /^\s*exec\s+(["']).*COMMONSDIR[^\/]*/, 'exec \1${PROGDIR}')
  end
end
