mm
==

a PyEZ based utility to Maintain Many netconf enabled network devices

If you are someone who maintains some number of network devices on a 
network, you sometimes want to run a "show" command or a "configure"
command on all or some of those devices.  It's really boring to ssh
into each device and do a  "show" or "config" 
Life is too short for that sort of thing.

mm allows you to run show or configure commands on one or many devices.
You can use it by specifying a list of hostnames or IP addresses
on the command line, or you can define arbitary groups of devices using
a python dictionary that is defined at the top of the script.
e.g. all_firewalls, all_edge_routers, my_favorite_devices

The utility also allows you to specify a file of show or configuration
commands if you want to do several show or configuration commands.

The command line arguments can be given in (almost) any order, which
ever way makes the most sense for you.  The only exception is if you
are specifying a file of commands, that filename must follow a -f

Some examples:

   mm -s 192.168.1.250 "show int terse"
   
   mm -s all_edge_routers "show bgp summary"
   
   mm -s 192.168.1.250 all_edge_routers -f some_file_name.txt
   
   mm -c 192.168.1.250 my_favorite_routers -c 'set int lo0 description "I am a loopback"'
   
   mm -c -f some_file_name.txt my_favorite_routers
   
You can also specify -d (for debug) on the command line, and watch what the utility is doing.

If you have any questions/problems, please write to me.
