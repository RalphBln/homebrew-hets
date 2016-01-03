require 'formula'
require "language/haskell"

class HetsDependencies < Formula
  include Language::Haskell::Cabal

  url "https://gist.githubusercontent.com/0robustus1/9049050/raw/a9c8e0dcbefef624090b6d3bce279fd73c579598/install_cabal_hets_deps.sh"
  homepage 'https://gist.github.com/0robustus1/9049050'
  sha1 'cfa0ebdb51e6654ca3cea926b8e3106cda178de1'
  version '0.1.4'

  depends_on 'ghc'
  depends_on 'cabal-install'
  depends_on 'glib'
  depends_on 'cairo'
  depends_on :x11
  depends_on 'gtk'
  depends_on 'gettext'
  depends_on 'fontconfig'
  depends_on 'freetype'

  def install
    ghc_prefix = `ghc --print-libdir | sed -e 's+/lib.*/.*++g'`.strip
    opts = ['--force-reinstalls', '--enable-documentation', '-p', '--global', "--prefix=#{ghc_prefix}"]
    packages_list = [
    %w{
      gtk2hs-buildtools
    }, %w{
      gtk -fhave-quartz-gtk
    }, %w{
      aterm
      random
      utf8-string
      xml
      fgl
      HTTP
      haskeline
      HaXml
      hexpat
      uni-uDrawGraph
      parsec1
      wai-extra
      warp-3.1.12
      tar-0.4.2.2
    }]
    system('cabal update')
    packages_list.each do |packages|
      cabal_install(*(opts + packages))
    end
    system('ghc-pkg hide parsec1')
  end
end
