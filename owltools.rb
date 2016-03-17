require "formula"

class Owltools < Formula
  version_commit = 'de2b683ce9196f7f73d994009bd562e25313a1ed'
  the_version = '0.2.2-SNAPSHOT'
  the_revision = '1'
  homepage 'https://github.com/owlcollab/owltools'
  head 'https://github.com/owlcollab/owltools.git', :using => :git
  url 'https://github.com/owlcollab/owltools.git', :using => :git, :revision => version_commit
  version "#{the_version}-#{the_revision}"

  depends_on :java
  depends_on 'maven'

  def install
    Dir.chdir('OWLTools-Parent') do
      system('mvn clean install')
    end

    # There are two files called obo-roundtrip:
    # one in OWLTools-Oort and one in OWLTools-Runner
    FileUtils.mv('OWLTools-Oort/bin/obo-roundtrip',
                 'OWLTools-Oort/bin/obo-roundtrip-oort')

    %w(OWLTools-NCBI OWLTools-Oort OWLTools-Runner).each do |dir|
      prefix.install Dir["#{dir}/bin/*"]
    end
  end

  def caveats
  end
end
