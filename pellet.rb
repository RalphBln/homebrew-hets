require "formula"

class Pellet < Formula
  @@version_commit = 'c018458d1a0ae953566e6fe0da8885d76ddf142d'
  the_version = '2.3.1'
  homepage 'http://clarkparsia.com/pellet'
  head 'https://github.com/Complexible/pellet.git', :using => :git
  url 'https://github.com/Complexible/pellet.git', :using => :git, :revision => @@version_commit
  version the_version

  option 'without-script', 'includes a pellet script which is placed in PATH'

  depends_on :java
  depends_on 'ant'

  def install
    system('ant')
    prefix.install Dir['dist/*']

    if build.with? 'script'
      bin.mkdir
      bin.join('pellet').open('w') do |f|
        f.write <<-SH
#!/bin/sh
if [ -n "${JAVA_HOME}" -a -x "${JAVA_HOME}/bin/java" ]; then
  java="${JAVA_HOME}/bin/java"
else
  java=java
fi
if [ -z "${pellet_java_args}" ]; then
  pellet_java_args="-Xmx512m"
fi
exec ${java} ${pellet_java_args} -jar #{prefix.join('lib/pellet-cli.jar')} "$@"
        SH
      end
    end
  end

  def caveats
  end
end
