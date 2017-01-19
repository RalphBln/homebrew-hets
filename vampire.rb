require 'formula'

class Vampire < Formula
  homepage 'http://www.spass-prover.org/index.html'
  url 'http://www.cs.miami.edu/~tptp/CASC/J8/SystemsSources/Vampire---4.0.tgz'
  version '4.0'
  sha256 'f0f81f904df260ead8c32ab7e0f31292f2f59f28cb4c1374fdd2a629b3cb12a0'

  depends_on 'gcc' => :build

  def install
    # Static is not possible on macOS unless all linked files are compiled
    # with it.
    inreplace 'Makefile' do |s|
      s.gsub! '-static ', ''
    end
    system('make clean')
    system('make version.cpp')
    system('make obj')
    system('make vampire')
    bin.install('vampire')
  end

  def caveats
    "This version of vampire is not portable to other Macs."
  end
end
