require "formula"

class Owltools < Formula
  version_commit = 'de2b683ce9196f7f73d994009bd562e25313a1ed'
  the_version = '0.2.2-SNAPSHOT'
  the_revision = '2'
  homepage 'https://github.com/owlcollab/owltools'
  head 'https://github.com/owlcollab/owltools.git', :using => :git
  url 'https://github.com/owlcollab/owltools.git', :using => :git, :revision => version_commit
  version "#{the_version}-#{the_revision}"

  depends_on :java
  depends_on 'maven' => :build

  def install
    # build
    Dir.chdir('OWLTools-Parent') do
      system('mvn clean install -Dmaven.test.skip.exec=true')
    end

    # install the software
    %w(OWLTools-NCBI
       OWLTools-Oort
       OWLTools-Runner).each do |dir|
      prefix.join(dir).mkpath
      prefix.join(dir).install("#{dir}/bin")
    end


    # create and install executable files
    Dir.mktmpdir('homebrew_bin') do |executables_dir|
      write_executables(executables_dir)
      bin.install Dir["#{executables_dir}/*"]
    end
  end

  def caveats
  end

  protected

  def write_executables(executables_dir)
    write_executable('OWLTools-NCBI/bin/ncbi2owl',                    "#{executables_dir}/ncbi2owl")
    write_executable('OWLTools-Oort/bin/build-obo-ontologies.pl',     "#{executables_dir}/build-obo-ontologies.pl")
    write_executable('OWLTools-Oort/bin/create-ontology-project',     "#{executables_dir}/create-ontology-project")
    write_executable('OWLTools-Oort/bin/obo-assert-inferences',       "#{executables_dir}/obo-assert-inferences")
    write_executable('OWLTools-Oort/bin/obo-roundtrip',               "#{executables_dir}/obo-roundtrip-oort")
    write_executable('OWLTools-Oort/bin/ontology-release-runner',     "#{executables_dir}/ontology-release-runner")
    write_executable('OWLTools-Oort/bin/ontology-release-runner-gui', "#{executables_dir}/ontology-release-runner-gui")
    write_executable('OWLTools-Oort/bin/reasoner-diff',               "#{executables_dir}/reasoner-diff-oort")
    write_executable('OWLTools-Runner/bin/obo-roundtrip',             "#{executables_dir}/obo-roundtrip")
    write_executable('OWLTools-Runner/bin/owltools',                  "#{executables_dir}/owltools")
    write_executable('OWLTools-Runner/bin/phenolog-runner',           "#{executables_dir}/phenolog-runner")
    write_executable('OWLTools-Runner/bin/reasoner-diff.sh',          "#{executables_dir}/reasoner-diff.sh")
  end

  def write_executable(binary_path, executable)
    File.open(executable, 'w') do |f|
      f.puts <<FILE
#!/bin/bash
"#{prefix.join(binary_path)}" "$@"
FILE
    end
  end
end
