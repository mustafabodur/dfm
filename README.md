dfm
===

dfm Disk Free Monitor

Yet another filesystem free monitor.

The need is simple for the unix admininstrator, should not miss while a file system is near to fill and a warning system should not fill the inbox. 
Out of this need, dfm grew where we managed hundreds of unix servers. It has the basic and extended monitoring capabilities. 

In the basic mode you define the monitor groups, set threshold for file systems and mails will arrive when this point is passed. 

In the extended mode, you can set a two level threshold, watch for regular fill ratio, fill increase trend (example if fill ratio is at 1% warn),
estimated time of fill in minutes (like warn if at this fill ratio filesystem will be full in 30 minutes), or mixture of these.

There is also daily stats monitor where it draws ascii graph of filesystems change during a 24-hour interval. 

INSTALLATION

There are two operation modes simple and complex. For both copy the files in a directory, (or simply create a directory structure
/admins/dfm/ and copy the files) fix the paths if needed, fix the default email adressses and default domains in the script. 

For simple mode add a cron entry like  (-e is for email, -s for simple you can run it with out -e to see the output)

*/5 * * * * /admins/dfm/dftrend.pl -e -s 

And create or modify "dfopts" file as such 
80	/	operators	
90	/	unixsis
95	/	dba

The last column of this file is the user groups for receiving warning mails. For example operators will receive warning mails when  / filesystem is more than 80% full.
The user groups are defined in "dfusers" files. A sample is such:

operators        operator1@default.com,operator2@default.com
unixsis                root1@default.com,admin@default.com



In the complex or extended mode the posibilities are more and that's why its complex. 

In crontab you can enable extened mode with -ex ( -e is for email -lm for low threshold mark enabling)
*/5 * * * * /admins/dfm/dftrend.pl -e -ex -lm 

Instead of dfopts we use dftrend.opts file:


/                        90        1        95        500        50        unixsis 
/                        80        1        90        500        50        operators 
/opt        90        1        95        500        50        unixsis 
/opt        80        1        90        500        50        operators 


The file structure is as follows 
#filesystem       lowmark%  trend%        free%        timetofill%        mix        warngroup

Lowmark is the limit under it no warnings can kick in. It's the less critical  free value where you want  to set warning 
light yellow, enable trend, timetofill (aka ETA), and other triggers to warn. 

trend fill ratio, how fast filesystem is getting filled, its the ratio of increase of used space on default 5 minunte average
timetofill how many minites needs to fill the fs 100%. Sometimes filesystems become full with out giving much time to notice 
before filesystem is completely full. (Example, something is causing crash dumps, or somebody is decided to export a database dump 
in a wrong filesystem)
mix a weighted average of the three (trend, timetofill, and free) 
last column is who will be warned when of these conditions met

The users are defined as in simple mode: in dfusers.


Other Modes and switches

"-e" "-email" "email"
To enable email mode, when this is not enabled, output will be printed out.

"-v" -version" "version"
Just prints version
     
"test" "-test"  "-t"
Enables test mode, instead of sending mails to groups sends mails to the default email or test user email.
 
"-s" "simple" "-simple"  
Puts script in the simple monitor mode. Only disk free percent is monitored.

"debug" "-debug" "-d"
To debug with level. With greater debug ( -ex -d 3)  greater garbage comes.

"extended" "-extended"  "-ex"
Enables extended mode. You can monitor  more than free percent now like increase rate, time to fill.

"lowmark" "-lowmark" "-lm"
You enable the low threshold mark with this below the lowmark no warning mails are sent.

"noupdate" "-noupdate" "-nu"
Usefull for testing purposes, since everytime a statistics file is updated to calculate next runs avarages. 

"showbyte" "-showbyte" "-sb"
Human readable bytes, like 30G or 120M.       

