wdoekes build of (Garix) NetRadiant-custom for Ubuntu/Debian
============================================================

Radiant is the open source cross platform level editor for idTech games
like Quake III Arena.

There are at least three competing versions out there:

- 🔘 `GtkRadiant <https://github.com/wdoekes/gtkradiant-deb>`_ 1.6 (a
  continuation of *GtkRadiant 1.4*, maintained by TTimo);
- 🔘 `NetRadiant <https://github.com/wdoekes/netradiant-deb>`_ 1.5 (a
  continuation of the *GtkRadiant 1.5*, maintained by Xonotic);
- 👉 `NetRadiant-custom <https://github.com/wdoekes/nrcradiant-deb>`_ 1.5 (
  an early fork of *NetRadiant*, maintained by Garux).

(There are more versions, including ``darkradiant`` which actually ships
in the Ubuntu universe.)

This repository contains build tools to build Debian/Ubuntu packages for
`NetRadiant-custom <https://github.com/Garux/netradiant-custom>`_ along
with the *q3map2* compiler and *bspc* bot file builder.

In the `releases section <../../releases>`_, you might find some
precompiled debian packages... if you're lucky. But if there aren't any,
building for your specific Debian derivative should be a breeze.


Building NetRadiant-custom for your distro
------------------------------------------

Using Docker::

    ./Dockerfile.build [ubuntu/jammy]

If the build succeeds, the built Debian packages are placed inside (a
subdirectory of) ``Dockerfile.out/``.

The files may look similar to these::

    -     14,596  nrcradiant_1.5.0+20220528+1-0wjd1+ubu22.04_amd64.buildinfo
    -      3,199  nrcradiant_1.5.0+20220528+1-0wjd1+ubu22.04_amd64.changes
    -  4,935,336  nrcradiant_1.5.0+20220528+1-0wjd1+ubu22.04_amd64.deb
    -      7,632  nrcradiant_1.5.0+20220528+1-0wjd1+ubu22.04.debian.tar.xz
    -      1,305  nrcradiant_1.5.0+20220528+1-0wjd1+ubu22.04.dsc
    - 8,5897,202  nrcradiant_1.5.0+20220528+1.orig.tar.gz
    - 6,4066,598  nrcradiant-dbgsym_1.5.0+20220528+1-0wjd1+ubu22.04_amd64.ddeb
    -  5,595,956  nrcradiant-game-quake3_1.5.0+20220528+1-0wjd1+ubu22.04_all.deb

The ``nrcradiant*.orig.tar.gz`` contains source files from multiple
repositories. With ``SOURCE_VERSION`` files in the directories,
recording the exact versions. (NOTE: For the gamepacks, exact versions
might not be recorded.)

The ``nrcradiant*.deb`` holds files in::

    - /usr/bin (nrcradiant, mbspc, q2map, q3map2, ...)
    - /usr/lib/x86_64-linux-gnu/nrcradiant (plugins/modules)
    - /usr/share/nrcradiant (arch independent data files, images)

The ``nrcradiant-game-quake3*.deb`` holds files in::

    - /usr/share/nrcradiant/gamepacks/games/q3.game
    - /usr/share/nrcradiant/gamepacks/q3.game (game data)


Running NetRadiant-custom
-------------------------

Starting should be a matter of running ``nrcradiant``::

    $ dpkg -L nrcradiant | grep ^/usr/bin/
    /usr/bin/bspc
    /usr/bin/h2data
    /usr/bin/mbspc
    /usr/bin/nrcradiant
    /usr/bin/q2map
    /usr/bin/q3map2
    /usr/bin/qdata3

Game configuration will be stored in ``~/.config/nrcradiant``::

    $ find ~/.config/nrcradiant -type f | sort
    ~/.config/nrcradiant/1.5.0/global.pref
    ~/.config/nrcradiant/1.5.0/prtview.ini
    ~/.config/nrcradiant/1.5.0/q3.game/local.pref
    ~/.config/nrcradiant/1.5.0/q3.game/shortcuts.ini
    ~/.config/nrcradiant/1.5.0/radiant.log

If you set paths as follows::

    EnginePath = /usr/share/nrcradiant/gamepacks/q3.game/
    ExtraResoucePath = ~/.q3a/  (yes, it's ExtraResourcePath withour 'r')

Then shader lists are scanned in this order (continues even when found)::

    /usr/share/nrcradiant/gamepacks/q3.game/baseq3/default_shaderlist.txt
    /usr/share/nrcradiant/gamepacks/q3.game/baseq3/scripts/shaderlist.txt (read-write)
    /usr/share/nrcradiant/gamepacks/q3.game/baseq3/scripts/shaderlist.txt
    ~/.q3a/baseq3/scripts/shaderlist.txt
    ~/.q3a/scripts/shaderlist.txt

And shader image locations are scanned in this order (stops when found)::

    ~/.q3a/textures/common/watercaulk.jpg
    ~/.q3a/baseq3/textures/common/watercaulk.jpg
    /usr/share/nrcradiant/gamepacks/q3.game/baseq3/textures/common/watercaulk.jpg
    ~/.q3a/textures/common/watercaulk.tga
    ~/.q3a/baseq3/textures/common/watercaulk.tga
    /usr/share/nrcradiant/gamepacks/q3.game/baseq3/textures/common/watercaulk.tga


Other
-----

See `<README-quake3.rst>`_ for Quake3 specific setup.


BUGS/TODO
---------

* See if we can find an appropriate version better than
  1.5.0+20220215+3.

* BUG: openat(AT_FDCWD, "/usr/share/nrcradiant/gamepacks/q3.game/baseq3/scripts/shaderlist.txt", O_WRONLY|O_CREAT|O_TRUNC, 0666) = -1 EACCES

* Document/decide on handling the gamepacks:

  - do we want to record source versions, we don't right now;

  - use quake3 instead of q3 for naming, because of better findability;

  - only put one game in a gamepack, we may want to manually create
    gamepacks: the gtkradiant versions contain more contents (example
    maps).

* Right now there is only a tiny index.html in
  /usr/share/nrcradiant/docs. We *could* move that to
  /usr/share/doc/nrcradiant.

* The nrcradiant-game-quake3 has plenty of docs in
  /usr/share/nrcradiant/gamepacks/q3.game/docs. Do we want to move that
  to /usr/share/doc/nrcradiant?
