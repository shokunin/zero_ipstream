zero_ipstream
=============

Stream IPs from logstash to stdout for use with maptail or other programs

Building
--------
- Checkout source
- Bundle install
- rake ( builds the jar file )

Running
-------

java -jar zero_ipstream.jar /etc/settingsfile.yaml

Example config
--------------
see config/sets.yaml
    
    ---
    :servers:
    - 127.0.0.1
    - 172.16.15.192
    :port: 2112
    :ip_field_name: clientip


Example logstash config
-----------------------

  zeromq {
    address => ["tcp://0.0.0.0:2112"]
    mode => "server"
    topology => "pushpull"
    tags => ["mynginxlogs"]
  }

