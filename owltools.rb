require "formula"

class Owltools < Formula
  version_commit = '447e4156287580cd1510b0371a49c1c99e207d34'
  homepage 'https://github.com/owlcollab/owltools'
  head 'https://github.com/owlcollab/owltools.git', :using => :git
  url 'https://github.com/owlcollab/owltools.git', :using => :git, :revision => version_commit
  version '0.3.0'

  depends_on :java
  depends_on 'maven' => :build

  def install
    # build
    system('export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"')
    Dir.chdir('OWLTools-Parent') do
      system('mvn clean install -DskipTests')
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
    write_executable('OWLTools-Oort/bin/obo-roundtrip',               "#{executables_dir}/obo-roundtrip")
    write_executable('OWLTools-Oort/bin/ontology-release-runner',     "#{executables_dir}/ontology-release-runner")
    write_executable('OWLTools-Oort/bin/ontology-release-runner-gui', "#{executables_dir}/ontology-release-runner-gui")
    write_executable('OWLTools-Oort/bin/reasoner-diff',               "#{executables_dir}/reasoner-diff")
    write_executable('OWLTools-Runner/bin/owltools',                  "#{executables_dir}/owltools")
  end

  def write_executable(binary_path, executable)
    system("chmod +x #{prefix.join(binary_path)}")
    File.open(executable, 'w') do |f|
      f.puts <<FILE
#!/bin/bash
"#{prefix.join(binary_path)}" "$@"
FILE
    end
  end
end
