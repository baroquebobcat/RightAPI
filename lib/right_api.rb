#!/usr/bin/ruby
#
# Copyright 2009 RightScale, Inc.
# http://www.rightscale.com
# <user>
#
# Ruby API Wrapper for RightScale API functions
# Class: RightAPI
#
# Allows easier access to the RightScale API within your own ruby code and
# Has limited debugging & error handling at this point.
# 
# Requires rest_client Ruby gem available online.
# 'gem install rest-client' 
#  
# Example:
# api = RightAPI.new	
# api.log = true
# api.login(:user => 'user', :password => 'pass', :account => '1234')
# 
# Allows you to send API messages to RightScale in a standard format (see API reference)
# http://support.rightscale.com/15-References/RightScale_API_Reference_Guide
#
# resourceid returns id # of created object
# headers returns hash of returned http headers
# duration returns the time the api call took
#
# api.send(API_STRING,REST_TYPE, PARAMS)
# 	e.g.	API_STRING = "ec2_ssh_keys/1234"
#		REST_TYPE = GET | PUT | POST | DELETE 		
#		PARAMS = optional depending on call
#
# api.send("servers") 				Returns list of your servers
# 
# params = { 'deployment[nickname]' => 'my_deployment_name', 'deployment[description]' => 'my_description' }
# api.send("deployments","post",params)
#


require 'rubygems'
require 'restclient'

class RightAPI
  API_VERSION = '1.0'

  attr_accessor :api_version, :log, :debug, :api_url, :log_file, :puts_exceptions, :reraise_exceptions

  def initialize

    @api_version = API_VERSION
    @log_file_default = "rest.log"
    @api_url = "https://my.rightscale.com/api/acct/" if @api_url.nil?
    @puts_exceptions = true
    @reraise_exceptions = false
    @apiheader = {}
  end

  def login(opts={})
    puts "Debug mode on\n\n" if @debug

    @account = opts.delete :account

    @credentials = opts.dup

    @api_call = "#{@api_url}#{@account}"

    unless @log.nil?
      puts "logging=#{@log}" if @debug
      puts "log_file=#{@log_file}" if @debug
      @log_file == nil ? RestClient.log= @log_file_default : RestClient.log= @log_file
    end

    @apiobject = RestClient::Resource.new(@api_call, @credentials)
  rescue => e
    puts "Error: #{e.message}" if @puts_exceptions
    raise if @reraise_exceptions
  end

  def send(apistring, type = "get", params = {})
    @responsecode = ""
    api_version= { :x_api_version => @api_version, :api_version => @api_version }

    raise "No API call given" if apistring.empty?
    raise "Invalid Action: get | put | post | delete only" unless type.match(/(get|post|put|delete)/)

    @callstart = Time.now

    @reply = @apiobject[apistring].send(type.to_sym, api_version.merge(params))
    
    @time = Time.now - @callstart

    @apiheader = @reply.headers
    @resid = @apiheader[:location].match(/\d+$/) if @apiheader[:status].downcase.match(/201 created/)

    @reply

  rescue
    @responsecode = $!
    puts "Error: #{$!}" if @puts_exceptions
    raise if @reraise_exceptions

  end

  # Returns the resource id of the created object
  def resourceid
    @resid
  end

  # Show existing api connection string
  def show_connection
    puts @apiobject.inspect
  end

  # Returns length of time api call took
  def time
    @time.to_f
  end

  # returns hash of http headers returned
  def headers
    @apiheader
  end

  # Return xml of matching names
  def search(name="")
    self.send("servers?filter=nickname=#{name}")
  end

  def code
    @responsecode
  end
end
