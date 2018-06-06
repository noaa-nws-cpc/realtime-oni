How to Install
===============

Table of Contents
---------------

- [Other Documents](#other-documents)
- [Prerequisites](#prerequisites)
- [Steps to Install](#steps-to-install)

Other Documents
---------------

- [README](../README.md)
- [How to Run](HOW-TO-RUN.md)

Prerequisites
---------------

The following software must be installed on your system in order to install and use realtime-oni:

- [git](https://git-scm.com/book/en/v1/Getting-Started-Installing-Git)
- [CPC Perl5 Library](https://github.com/noaa-nws-cpc/cpc-perl5-lib)
- [GrADS v2.0.2 or later](http://cola.gmu.edu/grads/downloads.php)

To see which version of GrADS your system uses by default, enter:

    $ grads -blc "quit"

Steps to Install
---------------

### Download and install realtime-oni

These instructions assume that the realtime-oni app will be installed in `$HOME/apps`. If you install it in a different directory, modify these instructions accordingly.

1. Download realtime-oni (this creates a directory called `realtime-oni`):

    `$ cd $HOME/apps`
    
    `$ git clone https://github.com/noaa-nws-cpc/realtime-oni.git`

2. Install the application:

    `$ cd $HOME/apps/realtime-oni`
    
    `$ make install`

3. Add the environment variable `$REALTIME_ONI` to `~/.profile_user` or whatever file you use to set up your profile:

    `export REALTIME_ONI="${HOME}/apps/realtime-oni"`

### Setup daily SST archive

### Setup cron
