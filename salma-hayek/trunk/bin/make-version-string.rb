#!/usr/bin/ruby -w

# Despite its name, this script generates "build-revision.txt".

# Win32's installer's broken idea of "version number" forces us to have a
# version number of the form "a.b.c", and also forces us to ensure that
# a <= 255, b <= 255, and c <= 65535. If we don't, upgrading (replacing an
# old version with a new version) won't work. See here for the depressing
# details:
# http://msdn.microsoft.com/library/default.asp?url=/library/en-us/msi/setup/productversion.asp
# This script takes advantage of the fact that we have enough bits (8+8+16=32)
# to encode our project and salma hayek revision numbers, even if they're not
# conveniently arranged.

def getSubversionVersion(directory)
  command = "svnversion #{directory}"
  if `uname` =~ /CYGWIN/
    # svnversion is insanely slow on Cygwin using a samba share.
    # FIXME: we should probably have some sort of environment variables along the lines of "org.jessies.build.host.Linux" for this kind of thing. Especially if/when we finally get round to automating the distributions.
    linux_build_host = "duezer"
    directory = directory.sub(/^\/cygdrive\/[a-z]\//, "/home/#{`whoami`.chomp()}/")
    command = "ssh #{linux_build_host} svnversion #{directory}"
    $stderr.puts(command) # In case ssh(1) prompts for a password.
  end
  IO.popen(command) {
    |pipe|
    return pipe.readline()
  }
end

def extractVersionNumber(versionString)
  # The second number, if there are two, is the more up-to-date.
  # (In Subversion's model, commit doesn't necessarily require update.)
  if versionString.match(/^(?:\d+:)?(\d+)/)
    return $1.to_i()
  end
  return nil
end

project_root = ARGV.shift()
salma_hayek = ARGV.shift()

require "time.rb"
puts(Time.now().iso8601())
projectVersionString = getSubversionVersion(project_root)
puts(projectVersionString)
salmaHayekVersionString = getSubversionVersion(salma_hayek)
puts(salmaHayekVersionString)

fields = []
# The third field is called the build version or the update version and has a maximum value of 65,535.
fieldSize = 64 * 1024
# We try to separate the project_root and salma_hayek versions into different fields.
unifiedVersion = extractVersionNumber(projectVersionString) * fieldSize + extractVersionNumber(salmaHayekVersionString)
remainder = unifiedVersion
field = remainder % fieldSize
remainder /= fieldSize
fields.push(field)
# The second field is the minor version and has a maximum value of 255.
fieldSize = 256
field = remainder % fieldSize
remainder /= fieldSize
fields.push(field)
# The first field is the major version and has a maximum value of 255.
fieldSize = 256
field = remainder % fieldSize
remainder /= fieldSize
fields.push(field)

puts(fields.reverse.join("."))
