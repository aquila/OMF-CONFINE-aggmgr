#
# Copyright (c) 2006-2010 National ICT Australia (NICTA), Australia
#
# Copyright (c) 2004-2010 - WINLAB, Rutgers University, USA
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
#
# = abstractService.rb
#
# == Description
#
# This file defines the AbstractService class.
#

require 'rexml/document'
require 'rexml/element'
require 'stringio'
require 'base64'
require 'omf-common/mobject'

# JW 2010-03-05: The design notes below are no longer accurate because
# the AbstractService class has been modified to be more abstract, and
# not HTTP-specific.  It can now be used with any transport, including
# XMPP.  These design notes must be updated to reflect the changes.
# In the current implementation of the servers (see server.rb and
# serviceMounter.rb), the s_auth methods are ignored, because
# differences between XMPP and HTTP make it difficult to offer a
# uniform authorization interface (at least, given the existing use of
# s_auth in the cmc service).

#
# This class defines the general Service class. A Service implements the set of
# servlets, which are used to process a given HTTP request to the GridService
# Server. A Service is loaded by the GS Server (i.e. essentially a web server
# defined in 'ogs'rb'.
# This class is meant to be sub-classed for a particular type of Service.
# This class not only represent a single Service instance (i.e. a set of
# servlets), but it also provides a class-wide array of all the Service
# instances currently associated with the GS Server.
#
# Some design notes on how Service handles HTTP request processing:
#
# Instead of declaring a separate servlet for every method, I have a
# 'service' method which takes a name and a block. Help messages and
# parameter are declared with 's_description', and 's_param' respectively. This
# allows me to build the xml file describing the entire service
# automatically.
#
# Also check out the 's_auth' tag. This will first call the method
# declared ':authorize' and only if it returns true will the actual
# service be called. Here I'm using a very trivial check for a single
# user and password to allow access to the service. In our case we can
# do the check you have in now, but if the user comes from the outside
# s/he will be asked for a password instead.
#
# If you run the included file, try http://localhost:2000/service1 for
# the listing, and http://localhost:2000/service1/bad for a service
# protected by a password.
#
# I hope the rest is self-explanatory. What can be added is automatic
# checking for required parameters now that they are declared, or
# filling in default values. I've also started on an XSL file to turn
# the XML into a more user-friendly form, but that is not ready yet.
#
class AbstractService < MObject

  @@services = Hash.new
  @@serviceName = {} # contains a list of the various services mounted in the GridService daemon
  @@info = {} # contains a list of info related to the services in the serviceName list
  @@__info = nil
  @@__param = nil
  @@__param_list = nil
  @@__auth = nil

  #
  # Set the a short description information for this Service. This information
  # will be used to describe the Service when an HTTP GET request is made to
  # 'http://server:port/serviceName'
  #
  # - str = optional, the short description to use (default=nil)
  #
  def self.description(str = nil)
    if (str != nil)
      #@@info = str # We now have a table with the info for each class of Service
      @@info[self] = str
    end
    #@@info # See above comment
    @@info[self]
  end

  #
  # Set a particular help message for a given sub-service for this Service.
  # See the design notes in this class's description for more details
  #
  # - str = short help message to use
  #
  def self.s_description(str)
    @@__info = str
  end

  #
  # Set a particular parameter for a given sub-service for this Service.
  # See the design notes in this class's description for more details
  #
  # - name = name of the parameter to set
  # - value = value for that parameter
  # - info = short text description for that parameter
  # - default = optional, default value (default=nil)
  #
  def self.s_param(name, value, info, default = nil)
    p = @@__param ||= {}
    p_list = @@__param_list ||= []
    p[name] = {
      :info => info,
      :value => value,
      :isReq => (value =~ /\[/) != 0, # optional param start with '['
      :default => default
    }
    p_list << name
  end

  #
  # Set a particular authentication method for a given sub-service for this
  # Service. See the design notes in this class's description for more details
  #
  # - methodName = authentication to use
  #
  def self.s_auth(methodName)
    @@__auth = methodName
  end

  #
  # Associate a given sub-service of this Service with the block of command
  # responsible for realizing it.
  # See the design notes in this class's description for more details
  #
  # - mount = name of the sub-service, i.e. the mount point for the command
  #           block, e.g. 'http://server:port/Service/MountPoint'
  # - proc = optional (default=nil)
  # - &block = the block of commands that implement the sub-service
  #
  def self.service(mount, opts = {}, proc = nil, &block)
    #MObject.debug(serviceName, "defining '#{mount}'")
    proc ||= block
    services = @@services[self] || {}
    services[mount] = {
      :proc => proc,
      :info => @@__info,
      :param => @@__param,
      :param_list => @@__param_list,
      :auth => @@__auth
    }.merge(opts)
    @@services[self] = services
    @@__info = nil
    @@__param = nil
    @@__param_list = nil
    @@__auth = nil
  end

  #
  # Set the name of this Service (used by sub-classes to define their own name)
  #
  # - serviceName =  name of this Service
  #
  def self.name(serviceName)
    @@serviceName[self] = serviceName
  end

  #
  # Return the name of this Service
  #
  # [Return] the name of this Service
  #
  def self.serviceName
    # This method has been modified to accomodate the new serviceName list
    # s = self.to_s.downcase
    # s[/(.*)service/,  1] || s
    if @@serviceName[self].nil?
      s = self.to_s.downcase
      # remove a potentially trailing 'service'
      @@serviceName[self] = s[/(.*)service/,  1] || s
    end
    @@serviceName[self]
  end

  def self.serviceCalls
    @@services[self]
  end

  #
  # Configure this Service instance through a hash of options.
  # This will defined by the Service sub-classes.
  #
  # - config = a Hash with the configuration parameters
  #
  def self.configure(config)
  end

  #
  # Return the value of a given configuration parameter for this Service
  #
  # - req = the HTTP Request with all the parameters
  # - name = the name of the parameter to return
  #
  # [Return] a String with the value of the required parameter
  #
  def self.getParam(req, name)
    p = req.query[name]
    p.gsub!(" ","+")
    if (p == nil)
      raise HTTPStatus::BadRequest, "Missing parameter '#{name}'"
    end
    p
  end

  #
  # Return the value of a given configuration parameter for this Service,
  # if this parameter is not present in the request, return a default value
  #
  # - req = the HTTP Request with all the parameters
  # - name = the name of the parameter to return
  # - default = the default value to return
  #
  # [Return] a String with the value of the required parameter
  #
  def self.getParamDef(req, name, default)
    p = req.query[name]
    p.gsub!(" ","+")
    if (p.nil?)
      return default
    else
      return p
    end
  end

  #
  # Return an XML element with the description of this Service
  #
  # [Return] an XML element describing this Service
  #
  def self.to_xml(parentEl)
    topEl = parentEl.add_element('serviceGroup', {'name' => self.serviceName})
    # Table @@info contains info for each class of Services
    #if ((info = self.description) != nil)
    if ((info = @@info[self]) != nil)
      topEl.add_element('info').text = info
    end
    services = @@services[self] ||= {}
    services.keys.sort.each { |k|
      v = services[k]
      s = topEl.add_element('service', {'name' => k})
      if (info = v[:info])
        s.add_element('info').text = info
      end
      if (params = v[:param])
        args = s.add_element('args')
        v[:param_list].each { |name|
          attrs = v[:param][name]
          arg = args.add_element('arg',
                                 { 'name' => name,
                                   'value' => attrs[:value],
                                   'isRequired' => attrs[:isReq]
                                 })
          if attrs[:info]
            arg.add_element('info').text = attrs[:info]
          end
        }
      end
    }
    topEl
  end
end # class AbstractService



#########################################
#
# What follows are usage examples
#
#########################################
if $0 == __FILE__

  class Service1 < AbstractService

    s_description 'Foo is a typical service'
    s_param :x, 'xcoord', 'x coordinates of location'
    s_param :domain, '[sb_name]', 'domain for which to apply this action'
    service 'foo' do |req, res|
      res.body = "Foo. Always foo."
    end

    s_description 'Bar is a typical service'
    s_param :domain, '[sb_name]', 'domain for which to apply this action'
    service 'bar' do |req, res|
      res.body = "Bar. Where is the beer."
    end

    s_auth :authorize
    service 'bad' do |req, res|
      res.body = "Bad Service, it's a habbit."
    end


    def self.authorize(req, res)
      puts "Checking authorization"
      WEBrick::HTTPAuth.basic_auth(req, res, 'orbit') {|user, pass|
        # this block returns true if
        # authentication token is valid
        isAuth = user == 'gnome' && pass == 'super'
        puts "user: #{user} pw: #{pass} isAuth: #{isAuth}"
        isAuth
      }
      true
    end
  end

  class Service2 < AbstractService

    s_description 'Making soup is important'
    s_param :name, 'str', 'Name of soup'
    s_param :servings, '[number]', 'Number of servings'
    service 'makeSoup' do |req, res|
    end

  end

  def dump()
    doc = REXML::Document.new
    services = doc.add(REXML::Element.new("services"))
    Service1.to_xml(services)
    Service2.to_xml(services)
    formatter = REXML::Formatters::Default.new
    formatter.write(doc,$stdout)
  end

  def start_server()
    require 'webrick'
    server = WEBrick::HTTPServer.new({:Port => 2000})
    Service1.mount(server)

    trap("INT") { server.shutdown }
    server.start
  end

  start_server

end
