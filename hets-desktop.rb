require "formula"
require 'rexml/document'

class HetsDesktop < Formula
  @@version_commit = '430ab7208b425d007aa2d7e035eb0a3329da20bc'
  @@version = '0.100.0'
  homepage 'http://hets.eu'
  head 'https://github.com/spechub/Hets.git', :using => :git
  url 'https://github.com/spechub/Hets.git', :using => :git, :revision => @@version_commit
  version @@version
  revision 1

  bottle do
    root_url 'http://hets.eu/downloads/hets/macOS'
    sha256 '2a6ed095ed9336afd407a62ddc85f2b31601e22a012e67728bfcf44f9ecbe173' => :mavericks
    sha256 '2a6ed095ed9336afd407a62ddc85f2b31601e22a012e67728bfcf44f9ecbe173' => :yosemite
    sha256 '2a6ed095ed9336afd407a62ddc85f2b31601e22a012e67728bfcf44f9ecbe173' => :el_capitan
    sha256 '2a6ed095ed9336afd407a62ddc85f2b31601e22a012e67728bfcf44f9ecbe173' => :sierra
    sha256 '2a6ed095ed9336afd407a62ddc85f2b31601e22a012e67728bfcf44f9ecbe173' => :high_sierra
  end

  depends_on 'haskell-stack' => :build
  depends_on 'glib' => :build
  depends_on 'binutils' => :build

  depends_on 'cairo' => :build
  depends_on 'fontconfig' => :build
  depends_on 'freetype' => :build
  depends_on 'gettext' => :build
  depends_on 'gtk' => :build

  depends_on :x11
  depends_on 'hets-commons'
  depends_on 'udrawgraph'
  depends_on 'libglade'

  # depends_on 'darwin' => :recommended
  depends_on 'eprover' => :recommended
  # depends_on 'factplusplus' => :recommended
  depends_on 'leo2' => :recommended
  depends_on 'owltools' => :recommended
  depends_on 'pellet' => :recommended
  depends_on 'spass' => :recommended
<<<<<<< HEAD
=======
  # depends_on 'vampire' => :recommended
>>>>>>> Update Hets packaging.

  def install
    make_compile_target = 'hets.bin'
    make_install_target = 'install-hets'
    executable = 'hets'
    binary = "hets.bin"

    puts "Preparing the setup..."
    system(%(stack setup))
    system(%(make stack))

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
