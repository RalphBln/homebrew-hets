require "formula"

class Pellet < Formula
  @@version_commit = 'bb99c19f9b9abf4e2c9e65098ee3e4d624e14894'
  the_version = '2.4.0'
  homepage 'http://clarkparsia.com/pellet'
  head 'https://github.com/Complexible/pellet.git', :using => :git
  url 'https://github.com/Complexible/pellet.git', :using => :git, :revision => @@version_commit
  version "#{the_version}-0-SNAPSHOT"

  depends_on :java
  depends_on 'maven'

  def install
    system('mvn clean install -DskipTests')
    prefix.install Dir['cli/target/pelletcli/*']
  end

  def caveats
  end
end
