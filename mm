#!/usr/local/bin/python2.7

# Dave Curado davec@curado.org 
# Wed Jun 11 16:13:43 EDT 2014

# todo
# 1 - allow mm to continue on even after ping failure
# 2 - save up errors and dump them out at the end
# 3 - get some feedback about output options
# 4 - deal with set vs. load terminal

import sys
import os
import getpass
from jnpr.junos import Device
from jnpr.junos.utils.config import Config

netconf_port = 22

macros = {
   'border_routers': 'border1.scl3.mozilla.net, border2.scl3.mozilla.net, border1.pao1.mozilla.net, border1.sjc2.mozilla.net, border1.phx1.mozilla.net, border2.phx1.mozilla.net',
   'pop_firewalls':'fw1.pao1.mozilla.net,fw1.sjc2.mozilla.net',
   'scl3_firewalls':'fw1.scl3.mozilla.net, fw1.releng.scl3.mozilla.net, fw1.corp.scl3.mozilla.net',
   'office_firewalls':'fw1.sfo1.mozilla.net, fw1.mtv2.mozilla.net, fw1.yvr1.mozilla.net, fw1.lon1.mozilla.net, fw1.tpe1.mozilla.net, fw1.akl1.mozilla.net, fw1.par1.mozilla.net, fw1.pdx1.mozilla.net, fw1.tor1.mozilla.net, fw1.pek1.mozilla.net',
}

def main ():

    ################################################################
    # deal with command line arguments
    ################################################################

    command_file = 0
    action, hosts, command, filename, debug = handle_command_line_args()
    if debug:
       print "***debug: action is: %s" % action
       print "***debug: command line host list: %s" % hosts
       if len(command) > 0:
          print "***debug: command is: %s" % command
    if len(filename) > 0:
        command_file = 1
        if debug:
           print "***debug: command file specified."
           print "***debug: filename is: %s" % filename

    ################################################################
    # expand macro-names into list of hosts if applicable
    ################################################################

    device_list = []

    # for each host mentioned on the command line, check if it is actually a macro
    for host in hosts:
       if host in macros:
          if debug:
             s = '\'' + host + '\''
             print "***debug: found host %s in dict" % s
          for device in macros[host].split(","):
             # remove any spaces
             device2 = device.replace(' ','')
             device_list.append(device2)
       else:
          device_list.append(host)

    if debug:
       print "***debug: list of devices: "
       for device in device_list:
          print "***debug: \t%s" % device
 
    ################################################################
    # check that each device answers a ping
    ################################################################

    for device in device_list:
       if debug:
          print "***debug: pinging on %s" % device
       if debug:
          print "***debug: \tpinging on %s" % device
       response = os.system("ping -q -c 1 -W 500 " + device + " >/dev/null")
       if response != 0:
          print "device: %s did not answer a ping, so I am stopping now. wah, wah, wah..." % device
          sys.exit(2)

    ################################################################
    # now do the show command(s) or config statement(s) to each device
    ################################################################

    login = getpass.getuser()
    if debug:
       print "login is %s" % login
    password = getpass.getpass('your password? ')

    for device in device_list:
       if debug:
          print "***debug: working on device: %s" % device
       else:
          print '-----------------------------------------------------'
          print "working on %s\n" % device,
          print '-----------------------------------------------------'
       if action == 'show':
          if (command_file == 0):
             # do this if it is a single show command
             do_show(device, command, debug, command_file, login, password)
          else:
             # do this if it is a file of show commands
             do_show(device, filename, debug, command_file, login, password)
       if action == 'config':
          if (command_file == 0):
             # do this if it is a single configuration command
             do_config(device, command, debug, command_file, login, password)
          else:
             # do this if it is a file of configuration commands
             do_config(device, filename, debug, command_file, login, password)

    sys.exit(0)

#-------------------------------------------------------------
def handle_command_line_args(): 
#-------------------------------------------------------------
    """ 
    Parse command line arguments.  
    If it doesn't look right, show usage().
    Else, return the action, list of hosts, and the command
    """

    debug = 0
    action = ''
    command = ''
    filename = ''
    device_list = ''
 
    # turn sys.argv into a list
    args = list(sys.argv)
    # if the person just typed the program name, display usage
    if len(args) < 2:
        usage()
        sys.exit(1)
    # if the person used -h or --help as an argument, display usage
    if ("-h" in args):
        usage()
        sys.exit(0)
    if ("--help" in args):
        usage()
        sys.exit(0)
    # if the person didn't specify at least -s|-c, one device, and one command, display usage
    if len(args) < 4:
        usage()
        sys.exit(1)
    # get rid of program name
    args.pop(0)
    # determine if the person wants a "show" or "config" command
    if ("-s" in args):
       action = 'show'
       args.remove("-s")
    if ("-c" in args):
       action = 'config'
       args.remove("-c")
    # determine if the person asked for debug mode
    if ("-d" in args):
       debug = 1
       args.remove("-d")
    # determine if the person provided a file of commands or just a single command
    if ("-f" in args):
       for i in (i for i,x in enumerate(args) if x == "-f"):
           i = i + 1
       filename = args[i]
       args.remove(args[i])
       args.remove("-f")
    else:
       command = args.pop(len(args)-1)

    hosts = args
    return action, hosts, command, filename, debug

#-------------------------------------------------------------
def usage():
#-------------------------------------------------------------

    print 'usage: %s -s | -c [-d] list_of_network_devices "the command you want to run" or -f inputfile' % sys.argv[0]

#-------------------------------------------------------------
def do_show(device, cmd, debug, command_file, login, pw):
#-------------------------------------------------------------

    global netconf_port

    if (command_file == 0):
       if debug:
           print '***debug: sending command: %s' % cmd

       # do the single line thing here
       dev = Device(host=device, user=login, password=pw, port=netconf_port)
       try:
          dev.open()
          if debug:
             print "*** Connected to " + device 
       except:
           print "\nConnection to %s failed. :-(" % device
           print "mis-typed your password maybe?"
           print "exiting."
           sys.exit(2)
       print dev.cli(cmd)
       print '-----------------------------------------------------'
       dev.close()
       
    else:
       dev = Device(host=device, user=login, password=pw, port=netconf_port)
       try:
          dev.open()
          if debug:
             print "*** Connected to " + device 
       except:
           print "\nConnection to %s failed. :-(" % device
           print "mis-typed your password maybe?"
           print "exiting."
           sys.exit(2)

       if debug:
           print '***debug: command file is %s' % cmd
           print '***debug: reading the file...'

       try:
          f = open(cmd,'r')
          show_commands = f.readlines() 
          f.close()
       except IOError:
          print "Error: cound not find or read file: %s" % cmd
       else:
          for command in show_commands:
             if len(command) > 1:
                if debug:
                   print "***debug: sending the following command: %s" % command
                print dev.cli(command)
                print '-----------------------------------------------------'
       dev.close()

#-------------------------------------------------------------
def do_config(device, cmd, debug, command_file, login, pw):
#-------------------------------------------------------------

    global netconf_port

    if (command_file == 0):
       if debug:
           print '***debug: configuring command: %s' % cmd

       # do the single line thing here
       dev = Device(host=device, user=login, password=pw, port=netconf_port)
       try:
          dev.open()
          if debug:
             print "*** Connected to " + device 
       except:
           print "\nConnection to %s failed. :-(" % device
           print "mis-typed your password maybe?"
           print "exiting."
           sys.exit(2)
       cu = Config(dev)
       cu.load(cmd, format='set')
       cu.pdiff()
       if cu.commit():
          print "commit OK"
          dev.close()
          print '-----------------------------------------------------'
       else:
          print "commit failed! exiting now."
          dev.close()
          sys.exit(2); 
    else:
       dev = Device(host=device, user=login, password=pw, port=netconf_port)
       try:
          dev.open()
          if debug:
             print "*** Connected to " + device 
       except:
           print "\nConnection to %s failed. :-(" % device
           print "mis-typed your password maybe?"
           print "exiting."
           sys.exit(2)
       cu = Config(dev)

       if debug:
           print '***debug: command file is %s' % cmd
           print '***debug: reading the file...'
       try:
          f = open(cmd,'r')
          config_commands = f.readlines() 
          f.close()
       except IOError:
          print "Error: cound not find or read file: %s" % cmd
       else:
          for command in config_commands:
             if len(command) > 1:
                if debug:
                   print "***debug: configuring the following: %s" % command
                cu.load(command, format='set')
          cu.pdiff()
          if cu.commit():
             print "commit OK"
             dev.close()
          else:
             print "commit failed! exiting now"
             dev.close()
             sys.exit(2); 
       dev.close()

#-------------------------------------------------------------
if __name__ == '__main__':
    main ()
#-------------------------------------------------------------

