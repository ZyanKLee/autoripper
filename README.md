# zyanklee's autoripper

autoripper is a wrapper script which uses udev rules, some cddb request and abcde
to check on insertion if a specific audio cd is already ripped and if not rip it.
I designed the autoripper for ubuntu linux, it may work out of the box for any other
linux distro, but I did not test it.

If you change the script to fit in with another linux distro, please send me a diff
so I can merge it with the original code.

For reporting issues and other stuff please visit my gitlab @ http://gitlab.argonet.de/ZyanKLee/autoripper


## contents

 * udev rules to start the wrapper script
 * wrapper script to check if cd is already ripped and to start abcde


## credits

I redistribute some scripts from xbmc forums, without explizit written permission.
If any author of those scripts wants me to remove them, please drop me a line.

Thanks to

 * Hitcher & N3MIS15 for their work on the library update script at
	http://forum.xbmc.org/showthread.php?tid=135074
 * XBMC Devs for their eventclient example scripts and libraries at
	https://github.com/xbmc/xbmc/tree/master/tools/EventClients


## dependencies

 * udev		# should already be installed
 * abcde
 * cd-discid
 * flac
 * eject
 * id3v2
 * normalize-audio

For the lazy ones:

	sudo apt-get install abcde cd-discid flac eject id3v2 normalize-audio


## installation

	sudo mkdir -p /usr/local/autoripper/
	sudo cp -r *.conf *.sh *.py icons lib LICENSE.GPL README.md /usr/local/autoripper/
	sudo cp rules.d/*.rules /etc/udev/rules.d/
	sudo chown -R root: /usr/local/autoripper/ /etc/udev/rules.d/


# license

see LICENSE.GPL