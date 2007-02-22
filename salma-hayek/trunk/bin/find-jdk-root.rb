#!/usr/bin/ruby -w

# What this script does
# ---------------------
#
# If javah(1) provided a way to ask for a list of the directories that need to
# be on the native compiler's include path, we might not have written this
# script. But it doesn't, so we needed a way to find the current JDK's
# include/ directory.
#
# As it happened, this script was also useful for finding such things as
# java(1) and "rt.jar".
#
# That's why, rather than make this script specific to the include/ directory,
# we output the path to the top-level directory of the JDK installation.
#
# Note, though, that when *running* rather than building our software, this
# script is not invoked. See "invoke-java.rb" for that case.
#
# How we choose a Java installation
# ---------------------------------
#
# There are many popular ways of choosing a particular Java installation, and
# they all have problems. The bad:
#
# * Using symbolic links requires a link for each program and makes it
#   unnecessarily difficult to switch if you need to test with a newer or
#   older version. Also, since the OS probably installed the symbolic
#   links in /usr/bin/, they're prone to being overwritten without your
#   direct consent. Other applications may (reasonably) assume that
#   the links haven't been meddled with. It makes it more likely that you're
#   testing with an unusual (and unsupported) configuration; if you rely on
#   the modified symbolic link to function, you won't necessarily recognize
#   this until someone tries to run your program on their standard system.
# * Using aliases requires an alias for each program, and is also specific to
#   your particular shell, so isn't usefully inherited by subprocesses which
#   can make testing more confusing.
# * Using $JAVA_HOME -- as was common practice in Java 1.1 days -- requires
#   everyone to abide by the (deprecated) convention. Because you're probably
#   still running the tools from $PATH regardless of any $JAVA_HOME setting,
#   it's easy to miss when this is set wrong. Using out-of-date header files,
#   for example, isn't always going to be easy to spot.
#
# The best:
#
# * Using $PATH is slightly awkward to switch versions (unless you're happy to
#   just keep prepending), but doesn't require you to know about every utility,
#   is understood by subprocesses, and is the default convention that everyone
#   uses anyway. This is Sun's (and Apple's) recommended way of working with
#   multiple versions.
#
# This is complicated somewhat when we're actually just looking for a JRE to
# run our stuff. While it's perfectly reasonable to expect developers to
# fiddle with $PATH to explicitly choose a JDK, it's less reasonable to expect
# users to know or care about any of this.
#
# There are several other common methods for end-users:
#
# * If you use JNLP, you can specify exactly your requirements, including
#   such things as "1.5 or later". This isn't an option for us, and I don't
#   think anyone's ever implemented it to choose between different vendors'
#   JVMs anyway; just between different versions of a single vendor's JVM.
# * On Debian-based systems, update-java-alternatives(1) fiddles the symbolic
#   links in /usr/bin/ to point to the various components of the selected Java
#   implementation. This has the disadvantage of applying to all applications
#   on the system (and most of the disadvantages of symbolic links).
# * On Debian-based systems, there's a seemingly independent scheme using a
#   configuration file /etc/jvm and shell scripts in /usr/share/java-common/.
#   This is flawed because although it lets you override the default for
#   your application, it doesn't let you do so in terms of version
#   requirements; you have to say exactly which JVM you want, making it no
#   better than just looking for your desired JVM in the right place. (The
#   configuration file doesn't even necessarily tell you which JVMs are
#   installed: it just lists some JVMs any of which may or may not be
#   available.)
#
# Writing our own launcher wouldn't solve this problem; it would just shunt
# it from Ruby to C++.

def find_jdk_root()
  require "pathname.rb"
  
  # Load helper libraries, coping with symbolic links to this script.
  bin = Pathname.new(__FILE__).realpath().dirname()
  require "#{bin}/target-os.rb"
  require "#{bin}/which.rb"
  
  # On Windows it's likely that the only Java on the user's path is an ancient
  # Microsoft Java in C:\WINNT\SYSTEM32.
  # This is unfortunately true even if the user has a properly installed JDK.
  if target_os() == "Cygwin"
    acceptableMajorVersions = [6, 5]
    acceptableMajorVersions.each() {
      |majorVersion|
      # This returns a native path, but universal.make already copes with that.
      registryKeyFile = "/proc/registry/HKEY_LOCAL_MACHINE/SOFTWARE/JavaSoft/Java Development Kit/1.#{majorVersion}/JavaHome"
      if File.exists?(registryKeyFile)
        contents = File.open(registryKeyFile).read();
        # Cygwin's representation of REG_SZ keys contains the null terminator.
        return contents.chomp("\0")
      end
    }
  end
  
  # Find java(1) on the path.
  java_on_path = which("java")
  
  # Our Windows "launcher.exe" uses the registry to find a JRE, so although
  # returning nil or an unsuitable Java here would be a problem for our build
  # system, it won't necessarily stop you running our stuff.
  # "invoke-java.rb" uses this script to find the JDK "tools.jar", but we cope
  # with installed JDKs which are not on the path, above.
  if java_on_path == nil
    return nil
  end
  
  # Neophyte users are likely to be using whatever's in /usr/bin, and that's
  # likely to be a link to where there's a JDK or JRE installation. So we need
  # to follow the links to the actual installation.
  java_in_actual_location = Pathname.new(java_on_path).realpath()
  
  # Assume we're in the JDK/JRE bin/ directory.
  java_bin = java_in_actual_location.dirname()
  
  # Assume the directory above the bin/ directory is the "home" directory; the
  # directory that contains bin/ and include/ and so on.
  jre_root = java_bin.dirname()

  jdk_root = jre_root
  # Debian's Sun JDK package depends on the JRE package, which provides the java
  # executable to the update-alternatives mechanism.
  # If only the JRE's installed, it's OK for this script to return a value
  # which points at an absent JDK.
  if jre_root.basename().to_s() == "jre"
    jdk_root = jre_root.dirname()
  end
  
  if target_os() == "Darwin"
    # On Mac OS, Apple use their own layout but provide a Home/ subdirectory
    # that contains a JDK-like directory structure of links to the files in
    # the Apple tree.
    # Unfortunately, they can point the /usr/bin/java link to the JRE (Versions/A/) rather than the JDK (Versions/CurrentJDK/).
    # So now we need a heuristic.
    if jdk_root.to_s().include?("/1.6")
      # If the user's path has a 1.6 "java" highest, we use the latest Java 6.
      # This will likely break when Java 6 becomes the default, if Apple continues to link to their JRE from /usr/bin/.
      jdk_root = "/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home/"
    else
      # Otherwise we use the latest Java 5.
      jdk_root = "/System/Library/Frameworks/JavaVM.framework/Versions/1.5/Home/"
    end
  end
  
  return jdk_root
end

if __FILE__ == $0
  puts(find_jdk_root())
  exit(0)
end
