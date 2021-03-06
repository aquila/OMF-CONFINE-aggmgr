#
# Copyright (c) 2006-2009 National ICT Australia (NICTA), Australia
#
# Copyright (c) 2004-2009 WINLAB, Rutgers University, USA
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# This is an OMF Definition for the existing application called 'otr2_mp'
# This definition will allow OMF entities to use and instrument this application
# Note: the application 'otr2_mp' was contributed by a student and is not 
# officially supported by the OMF/OML team
#
defApplication('test:app:otr2_mp', 'otr2_mp') do |a|

  a.path = "/bin/otr2_mp"
  a.version(1, 1, 2)
  a.shortDescription = "Programmable traffic sink"
  a.description = <<TEXT
otr is a configurable traffic sink. It contains port to receive
packet streams via various transport options, such as TCP and UDP.
This modified version introduces multipath routing, ie. OTG sends pkt via
multiple paths to the destination.
TEXT

  # Define the properties that can be configured for this application
  # 
  # syntax: defProperty(name, description, parameter, options = nil)
  #
  a.defProperty('sink', 'Processing to do with received packets [udpi|udpmi]', '--sink', {:type => :string, :dynamic => false})
  a.defProperty('udpmi:local_host', 'IP address of the local host ', '--udpmi:local_host', {:type => :string, :dynamic => false})
  a.defProperty("debug-level", "debug level [integer]","--debug-level")

  # Note: here we should have some Measurement Point definition...
end
