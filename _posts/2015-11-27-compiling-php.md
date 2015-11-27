---
title: Compiling PHP 5.6 for Raspbian
layout: post
---

In order to use the latest version of the [Owncloud news
app](https://etiennem.github.io/2015/02/18/owncloud/), I need at least PHP 5.6.
However, Raspbian being based on Debian Wheezy only provide PHP 5.4. Hence I
chose to compile PHP 5.6. This is an easier task than I thought!

I followed the tutorial [here](https://www.howtoforge.com/how-to-build-php-5.6-fpm-fastcgi-with-zend-opcache-and-apcu-for-ispconfig-3-on-debian-7-wheezy). 

# Prerequisites

First of all, choose a folder in which to download the sources. I chose
`$HOME/php-5.6/`. Then the folder in which to install PHP. I chose
`/opt/php-5.6`. You can now use the following commands to download and compile:

	sudo mkdir /opt/php-5.6/
	sudo chown username:groupname /opt/php-5.6/
	mkdir $HOME/php-5.6
	cd $HOME/php-5.6
	wget http://fr2.php.net/get/php-5.6.16.tar.bz2/from/this/mirror -O php-5.6.16.tar.bz2
	tar jxf php-5.6.*.tar.bz2
	cd php-5.6.16/

Then install the prerequisites to compile PHP 5.
	sudo apt-get install bzip2 libbz2-dev

# Compiling PHP

In order to see all available configure options, use `./configure --help`. For a working version of Owncloud, I used:

	./configure --prefix=/opt/php-5.6 --enable-mbstring --enable-zip --with-mysql --with-pdo-mysql --with-gd --enable-inline-optimization --with-bz2 --with-zlib --with-openssl --with-curl  --enable-fpm 
	make -j4
	make install

Copy `php.ini` and `php-fpm.conf` to the correct locations:

	cp $HOME/php-5.6/php-5.6.16/php.ini-production /opt/php-5.6/lib/php.ini
	cp /etc/php5/fpm/php-fpm.conf /opt/php-5.6/etc/php-fpm.conf

Your webserver configuration files need to take place in the
`/opt/php-5.6/etc/pool.d` folder that needs to be created. Then modify the last
line of `/opt/php-5.6/etc/php-fpm.conf` accordingly and copy their you old file
with `cp /etc/php5/fpm/pool.d/*.conf  /opt/php-5.6/etc/pool.d/`.

Eventually, take the init script [here](/files/init.d_php5-fpm) and copy it to
`/etc/init.d/php-5.6`.

Run `service php-5.6 start` and here we are! You have your own compiled php
version working.

Note: If you need the php CLI, you may have to modify the file `/usr/bin/php5`
in order to link it to `/opt/php-5.6/bin/php`.
