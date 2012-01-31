# Memcached Statistics in Lua

## Introduction 

This is a very **simple** script that prints out the keys, size and
expires dates of all items stored in a given memcached instance.

It connects directly to the server and sends a bunch of commands from
the
[memcached](http://code.sixapart.com/svn/memcached/trunk/server/doc/protocol.txt)
protocol.

The
[Lua socket](http://w3.impa.br/~diego/software/luasocket/home.html)
library.

On debian based systems you can get it with:

    aptitude install liblua5.1-socket2

## Installation & Usage

 1. Clone the repo:
    
        git clone git://github.com/perusio/memcached-inspect-keys.git
 
 2. Run the script to get the stats for a given instance:

        ./memcached-inspect-keys.lua 192.168.34.2 11212 
    
    This prints the keys, size and expire date of the items stored in
    the slabs allocated by the instance running 192.168.34.2 on port
    11212.
    
    Note that the default connection **timeout** for non local
    instances is **1 second**. You can alter that by passing a third
    argument to the script like this:
    
        ./memcached-inspect-keys.lua 192.168.34.2 11212 0.01
        
    This sets a connect timeout of 100 ms.
    
    By default the stats are dumped for **100 items** at most. If you
    need to get more items give the script a **fourth** argument, like
    this:
    
        ./memcached-inspect-keys.lua 192.168.34.2 11212 0.01 200
        
    This dumps **200 items** from each slab.    
    
    When called without any or all of the arguments the script uses
    the defaults, which are:
    
    * host: `localhost`
    
    * port: `11211`
    
    * timeout: `5 ms`
    
    * dump limit: `100` items.

Calling the script with `-h` or `--help` prints the usage instructions
and the defaults:
  
    ./memcached-inspect-keys.lua -h                                                                            

    Usage: ./memcached-inspect-keys.lua <host> <port> <timeout> [dump_limit]
    defaults
    host: localhost
    port: 11211
    timeout: 0.001000
    dump_limit: 100
