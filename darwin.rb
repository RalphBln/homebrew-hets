require 'formula'

class Darwin < Formula
  the_version = '1.4.4'
  homepage 'http://combination.cs.uiowa.edu/Darwin/'
  url "http://combination.cs.uiowa.edu/Darwin/files/darwin_v#{the_version}.tar.gz"
  version "#{the_version}"
  sha1 '2ce89af874f903afae9f58b454f711fedb8a1606'

  depends_on 'ocaml'

  def install
    ENV['MAKEFLAGS'] = '-j1'
    system('python ./configure.py')

    # The patch is needed for new OCaml versions. Darwin code is not maintained
    # anymore and it uses the removed function Array.create while Array.make is
    # its replacement.
    %w(src/context.ml src/problem_literals.ml).each do |srcfile|
      inreplace srcfile do |s|
        s.gsub! 'Array.create', 'Array.make'
      end
    end

    inreplace 'Makefile' do |s|
      s.gsub! ' -w $(WARNING_FLAGS)', ''
    end

    system('make')

    bin.install('darwin')
  end

  def caveats
  end
end
