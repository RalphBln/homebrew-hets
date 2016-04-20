require "formula"

class Factplusplus < Formula
  @@version_commit = '4cb618b0f26e8f7cd6a9243b0fc982a306d003ce'
  the_version = '1.6.4'
  homepage 'http://owl.man.ac.uk/factplusplus/'
  head 'https://bitbucket.org/dtsarkov/factplusplus.git', :using => :git
  url 'https://bitbucket.org/dtsarkov/factplusplus.git', :using => :git, :revision => @@version_commit
  version the_version

  depends_on :java
  depends_on 'gcc' => :build

  def install
    system('make')
    prefix.install('FaCT++.C/obj/libfact.jnilib')
    prefix.install('FaCT++.JNI/obj/libFaCTPlusPlusJNI.jnilib')
  end

  def caveats
  end
end
