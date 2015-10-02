---
title: Send e-mail in a shell script
layout: post
---

I find it useful to send e-mail from a script in some of my cron script in
case of an error append.  In order to do so, you first need to install a
couple of package:

	> apt-get install ssmtp mailutils

Then edit `/etc/ssmtp/ssmtp.conf`:

	root=username@free.fr
	mailhub=smtp.free.fr:465
	AuthUser=username
	AuthPass=myPassword
	hostname=raspberrypi
	FromLineOverride=YES
	UseTLS=YES

Using a Free e-mail address and a Free Internet connection, you do not need to
set the `AuthUser` and `AuthPass` keys. 

Then associate in the `/etc/ssmtp/revaliases` file username and mail adress:

	root:username@free.fr:smtp.free.fr:465
	www-data:username@free.fr:smtp.free.fr:465

You can now send e-mail using the following command:

	> echo "Body of the e-mail" | mail -s "Subject" username@free.fr

