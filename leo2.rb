require 'formula'

class Leo2 < Formula
  the_version = '1.7.0'
  homepage 'http://combination.cs.uiowa.edu/Darwin/'
  url "http://page.mi.fu-berlin.de/cbenzmueller/leo/leo2_v#{the_version}.tgz"
  version "#{the_version}"
  sha256 '02659042fd0966b2b42e2d966f5f1f38ca5f4395f8457d3d7c3169f3f53e58ac'

  # The compiler fails because of the friend declaration on macOS. It needs to
  # be patched according to the first commit of
  # https://github.com/niklasso/minisat/pull/17
  # Leo-II is discontinued, so this patch won't be included in upstream.
  patch :DATA

  depends_on 'ocaml' => :build
  depends_on 'camlp4' => :build

  def install
    Dir.chdir('src') do
      system('./configure', "--prefix=#{prefix}")
      system('make -j1 opt debug=false')
    end
    bin.install('bin/leo')
  end

  def caveats
<<MSG
You need to add these lines to your ~/.leoatprc in order for Leo-II to find the EProver:

e = /usr/local/bin/eprover
epclextract = /usr/local/bin/epclextract
MSG
  end
end
__END__
diff --git a/lib/minisat/core/SolverTypes.h b/lib/minisat/core/SolverTypes.h
index 1ebcc73..a16b401 100644
--- a/lib/minisat/core/SolverTypes.h
+++ b/lib/minisat/core/SolverTypes.h
@@ -47,7 +47,7 @@ struct Lit {
     int     x;

     // Use this as a constructor:
-    friend Lit mkLit(Var var, bool sign = false);
+    /* friend Lit mkLit(Var var, bool sign = false); */

     bool operator == (Lit p) const { return x == p.x; }
     bool operator != (Lit p) const { return x != p.x; }
@@ -55,7 +55,7 @@ struct Lit {
 };


-inline  Lit  mkLit     (Var var, bool sign) { Lit p; p.x = var + var + (int)sign; return p; }
+inline  Lit  mkLit     (Var var, bool sign = false) { Lit p; p.x = var + var + (int)sign; return p; }
 inline  Lit  operator ~(Lit p)              { Lit q; q.x = p.x ^ 1; return q; }
 inline  Lit  operator ^(Lit p, bool b)      { Lit q; q.x = p.x ^ (unsigned int)b; return q; }
 inline  bool sign      (Lit p)              { return p.x & 1; }
