require 'formula'

class Spass < Formula

  homepage 'http://www.spass-prover.org/index.html'
  url 'http://www.spass-prover.org/download/sources/spass39.tgz'
  version '3.9'
  sha256 '1797c3fbd1954189c812fbab7927880bad964ded400bae733a9938c7e6b09e85'

  def install
    system('make')
    bin.install('SPASS')
  end

  def caveats
  end

end
