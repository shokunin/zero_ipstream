#!/usr/bin/env ruby
require 'ffi-rzmq'
require 'json'
require 'yaml'

Thread.abort_on_exception = true


if ARGV.length < 1
  puts "provide a yaml config file\nSimilar to the following:"
puts """---
:servers:
- 127.0.0.1
- 172.16.15.192
:port: 2112
:ip_field_name: clientip"""
  exit! 2
end

settings = YAML::load( File.open( ARGV[0] ) )

def error_check(rc)
  if ZMQ::Util.resultcode_ok?(rc)
    false
  else
    STDERR.puts "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    caller(1).each { |callstack| STDERR.puts(callstack) }
    true
  end
end

ctx = ZMQ::Context.create(1)

pull_threads = []
settings[:servers].each do |i|
  pull_threads << Thread.new do
    pull_sock = ctx.socket(ZMQ::PULL)
    error_check(pull_sock.setsockopt(ZMQ::LINGER, 0))
    sleep 3
    rc = pull_sock.connect("tcp://#{i}:#{settings[:port]}")
    error_check(rc)
    
    #Here we receive message strings; allocate a string to receive
    # the message into
    message = ''
    rc = 0
    #On termination sockets raise an error where a call to #recv_string will
    # return an error, lets handle this nicely
    #Later, we'll learn how to use polling to handle this type of situation
    #more gracefully
    while ZMQ::Util.resultcode_ok?(rc)
      rc = pull_sock.recv_string(message)
      begin 
        myjson = JSON.parse(message)
        if myjson['@fields'].has_key? settings[:ip_field_name]
          puts myjson['@fields'][settings[:ip_field_name]]
        end
      rescue Exception => e
        #puts e.message
      end
    end
    
    # always close a socket when we're done with it otherwise
    # the context termination will hang indefinitely
    error_check(pull_sock.close)
    puts "Socket closed; thread terminating"
  end
end

pull_threads.each {|t| t.join}

puts "Done!"
