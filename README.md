dfm
===

dfm Disk Free Monitor

Yet another filesystem free monitor.

The need is simple for the unix admininstrator, should not miss while a file system is near to fill and a warning system should not fill the inbox. 
Out of this grew where we managed hundreds of unix server. It has the basic and extended monitoring capabilities. 

In the basic mode you define the monitor groups set threshold for file systems and mails will arrive when this point passes. 

In the extended mode, you can set a two level threshold, watch for regular fill ratio, fill increase trend (example if fill ratio is at 1% warn),
estimated time of fill in minutes (like warn if at this fill ratio filesystem will be full in 30 minutes), or mixture of these.

There is also daily stats monitor where it draws ascii graph of filesystems change during a 24-hour interval. 
