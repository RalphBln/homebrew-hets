require "formula"
require 'rexml/document'

class Hets < Formula
  # Both the version and the sha1 need to be adjusted when a new
  # dmg-version of hets is released.
  @@version_commit = '10b1256b32bd56a88c210d7a351c91e7ccdad27c'
  @@version_unix_timestamp = '1458061461'
  homepage "http://hets.eu"
  head "https://github.com/spechub/Hets.git", :using => :git
  url "https://github.com/spechub/Hets.git", :using => :git, :revision => @@version_commit
  version "0.99-#{@@version_unix_timestamp}"

  bottle do
    root_url 'http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets'
    revision 1
    sha256 '9c02c81ffa71632f5c15d8e8a957ae43b3847ac098f5a03001d6c574b0c3c942' => :mavericks
    sha256 '9c02c81ffa71632f5c15d8e8a957ae43b3847ac098f5a03001d6c574b0c3c942' => :yosemite
    sha256 '9c02c81ffa71632f5c15d8e8a957ae43b3847ac098f5a03001d6c574b0c3c942' => :el_capitan
  end

  depends_on 'ant' => :build
  depends_on 'cabal-install' => :build
  depends_on 'cairo' => :build
  depends_on 'fontconfig' => :build
  depends_on 'freetype' => :build
  depends_on 'gettext' => :build
  depends_on 'ghc' => :build
  depends_on 'glib' => :build

  depends_on 'graphviz'
  depends_on 'gtk'
  depends_on 'hets-lib'
  depends_on 'udrawgraph'
  depends_on :x11

  depends_on 'darwin' => :recommended
  depends_on 'eprover' => :recommended
  depends_on 'pellet' => :recommended
  depends_on 'spass' => :recommended

  def install
    inject_version_suffix

    puts 'Installing dependencies...'
    ghc_prefix = `ghc --print-libdir | sed -e 's+/lib.*/.*++g'`.strip
    opts = ['--force-reinstalls','-p', '--global', "--prefix=#{ghc_prefix}"]
    flags = %w(-f -gtkglade)
    system('cabal', 'update')

    system('cabal', 'install', '--only-dependencies', *flags, *opts)
    puts 'Compiling hets...'
    system('make -j 1 hets')
    system('strip hets')

    puts 'Compiling owl-tools...'
    system('make initialize_java')

    puts 'Putting everything together'
    local_lib = prefix.join('lib')

    local_lib.mkpath

    bin.install('hets')

    owl_tools = local_lib.join('hets-owl-tools')

    owl_tools.mkpath

    owl_tools.install('OWL2/OWL2Parser.jar')
    owl_tools.install('OWL2/OWLLocality.jar')
    owl_tools.install('DMU/OntoDMU.jar')
    owl_tools.install('CASL/Termination/AProVE.jar')
    owl_tools.join('lib').mkpath
    owl_api_jars = %w(lib/owlapi-osgidistribution-3.5.2.jar
                      lib/guava-18.0.jar
                      lib/trove4j-3.0.3.jar)
    owl_api_jars.each do |jar|
      owl_tools.join('lib').install("OWL2/#{jar}")
    end

    local_lib.install('magic/hets.magic')

    FileUtils.mv bin.join('hets').to_s, bin.join('hets-bin').to_s
    # install hets in bin as script which sets according
    # environment variables
    # (taken and adjusted from script file in hets root dir)
    bin.join("hets").open('w') do |f|
      f.write <<-BASH
#!/bin/bash
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export HETS_LIB=/usr/local/opt/hets-lib
export HETS_MAGIC=/usr/local/opt/hets/lib/hets.magic
export HETS_OWL_TOOLS=/usr/local/opt/hets/lib/hets-owl-tools
export HETS_APROVE=$HETS_OWL_TOOLS/AProVE.jar
export HETS_ONTODMU=$HETS_OWL_TOOLS/OntoDMU.jar
export PELLET_PATH=/usr/local/opt/pellet
exec "/usr/local/opt/hets/bin/hets-bin" "$@"
      BASH
    end
  end

  def caveats
  end

  protected

  def version_suffix
    if build.head?
      version = nil
      FileUtils.cd(cached_download) { version = `git log -1 --format=%ct`.to_i }
      version
    else
      @@version_unix_timestamp.to_i
    end
  end

  def inject_version_suffix
    File.open('rev.txt', 'w') { |f| f << version_suffix }
  end
end
