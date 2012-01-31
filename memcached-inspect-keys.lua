#!/usr/bin/env lua

-- memcached-inspect-keys.lua --- Display memcached stats in your console using Lua.

-- Copyright (C) 2012 António P. P. Almeida <appa@perusio.net>

-- Author: António P. P. Almeida <appa@perusio.net>

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- Except as contained in this notice, the name(s) of the above copyright
-- holders shall not be used in advertising or otherwise to promote the sale,
-- use or other dealings in this Software without prior written authorization.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- Use the Lua socket library.
local socket = require('socket')

-- Print the usage instructions.
if #arg == 1 and (arg[1] == '-h' or arg[1] == '--help') then
   print(string.format('Usage: %s <host> <port> <timeout> [dump_limit]', arg[0]))
   os.exit(1)
end

-- Get the host, port, dump_limit and connect timeout.
local __defaults = { port = '11211',
                     host = 'localhost',
                     timeout = 1,
                     dump_limit = 100 } -- defaults

local host = (not arg[1] and __defaults['host']) or arg[1]
local port = (not arg[2] and __defaults['port']) or arg[2]
local dump_limit = (not arg[4] and __defaults['dump_limit']) or arg[4]
local timeout
-- Set a very short timeout (10 ms) if the server is on the loopback.
if not arg[3] and host == 'localhost' then
   timeout = 0.001
else -- otherwise use 1s as the default or set to the given value
   timeout = (not arg[3] and __defaults['timeout']) or arg[3]
end

-- Sends a memcache command.
function send_memcache_command(server, port, command, ctimeout)

   -- Connect to the memcached server.
   local client = assert(socket.connect(server, port))
   -- Send the command.
   client:send(command .. '\r\n')
   -- Set the connection timeout to the given value or a default.
   client:settimeout(ctimeout, 't')
   -- Table to store the response.
   local response = {}
   while true do
      -- Read from the socket.
      local s, status, partial = client:receive()
      -- Exit if we reach any of the above states.
      if s == 'END\r\n'
         or s == 'DELETED\r\n'
         or s == 'OK\r\n'
         or s == 'NOT_FOUND\r\n' then break
      end
      -- Store the response in a table to be memory efficient.
      response[#response + 1] = s or partial
      -- Exit if there's a connection error.
      if status == 'closed' or status == 'timeout' then break end
   end
   -- Release the socket.
   client:close()
   -- Return the result.
   return response
end -- send_memcache_command

-- Prints a separator.
function print_separator (n)
   for i = 1, n do
      io.write(string.format('%s', '-'))
   end
   print()
end -- print_separator

-- Get all the items in memcache.
local r = send_memcache_command(host, port, 'stats items', timeout)
local nbr_slabs, nbr_items, tsize = 0, 0, 0
-- Print the headers.
print(string.format('%-72s %-12s %-20s', 'key', 'size', 'expires'))
print_separator(104)

local slabs = {}
-- Looping over all lines.
for k, line in pairs(r) do
   local slab_nbr = string.match(line, 'STAT items:(%d+):') -- get the slab number
   if slab_nbr and not slabs[slab_nbr] then -- proceed only if the slab is 'new'
      slabs[slab_nbr] = true -- store the slab number to avoid repetition
      nbr_slabs = nbr_slabs + 1
      local str = send_memcache_command(host, port,
                                        'stats cachedump ' .. slab_nbr .. ' ' .. dump_limit,
                                        timeout)
      for k, s in pairs(str) do -- loop on each slab for all the items
         for key, size, expire in string.gmatch(s, 'ITEM ([^%s]+) %[(%d+) b; (%d+) s%]') do
            -- Print the keys, size and expire date for each item on this slab.
            nbr_items = nbr_items + 1 -- total number of items
            tsize = tsize + size -- total size in bytes
            print(string.format('%-72s %-12d %-20s', key, size, os.date('%d.%b.%Y %H:%M:%S', expire)))
         end -- items
      end  -- slab loop
   end -- slab table (item)
end -- line

-- Print the totals of slabs and items.
print_separator(104)
print(string.format('total: %d items in %d slabs [size: %d]\n', nbr_items, nbr_slabs, tsize))
