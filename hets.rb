require "formula"
require 'rexml/document'

class Hets < Formula
  # Both the version and the sha1 need to be adjusted when a new
  # dmg-version of hets is released.
  @@version_commit = '6b19c8272f0789c62480f911d306c1b4d81a539a'
  @@version_unix_timestamp = '1458196355'
  homepage "http://hets.eu"
  head "https://github.com/spechub/Hets.git", :using => :git
  url "https://github.com/spechub/Hets.git", :using => :git, :revision => @@version_commit
  version "0.99-#{@@version_unix_timestamp}"

  bottle do
    root_url 'http://www.informatik.uni-bremen.de/~eugenk/homebrew-hets'
    revision 1
    sha256 '9e9f237c1fa05bfc1857694aad169fd74b71ab721e2eaa2f6a1fe2962167e598' => :mavericks
    sha256 '9e9f237c1fa05bfc1857694aad169fd74b71ab721e2eaa2f6a1fe2962167e598' => :yosemite
    sha256 '9e9f237c1fa05bfc1857694aad169fd74b71ab721e2eaa2f6a1fe2962167e598' => :el_capitan
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
  depends_on 'owltools' => :recommended
  depends_on 'pellet' => :recommended
  depends_on 'spass' => :recommended

  def install
    puts 'Installing dependencies...'
    ghc_prefix = `ghc --print-libdir | sed -e 's+/lib.*/.*++g'`.strip
    opts = ['--force-reinstalls','-p', '--global', "--prefix=#{ghc_prefix}"]
    flags = %w(-f -gtkglade)
    system('cabal', 'update')
    system('cabal', 'install', '--only-dependencies', *flags, *opts)
    puts "Compiling #{name}..."
    system("make -j 1 #{name}")
    system("strip #{name}")

    puts 'Compiling owl-tools...'
    system('make initialize_java')

    puts 'Putting everything together'
    local_lib = prefix.join('lib')
    local_lib.mkpath

    bin.install(name)

    owl_tools = local_lib.join("#{name}-owl-tools")

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

    FileUtils.mv bin.join(name).to_s, bin.join("#{name}-bin").to_s
    # install hets in bin as script which sets according
    # environment variables
    # (taken and adjusted from script file in hets root dir)
    bin.join(name).open('w') do |f|
      f.write <<-BASH
#!/bin/bash
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export HETS_LIB="${HETS_LIB:-#{HOMEBREW_PREFIX.join("opt", "hets-lib")}}"
export HETS_MAGIC="${HETS_MAGIC:-#{local_lib.join("hets.magic")}}"
export HETS_OWL_TOOLS="${HETS_OWL_TOOLS:-#{local_lib.join("hets-owl-tools")}}"
export HETS_APROVE="${HETS_APROVE:-$HETS_OWL_TOOLS/AProVE.jar}"
export HETS_ONTODMU="${HETS_ONTODMU:-$HETS_OWL_TOOLS/OntoDMU.jar}"
export PELLET_PATH="${PELLET_PATH:-#{HOMEBREW_PREFIX.join("opt", "pellet", "bin")}}"
exec "#{bin.join("#{name}-bin")}" "$@"
      BASH
    end
  end

  def caveats
  end
end
