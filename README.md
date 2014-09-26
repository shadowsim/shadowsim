shadowsim
=========

SIM Card tunnel for Alcatel OT-918D

You need BB-Firmware and mdlogger:

091c4a808bbe8c5eeb8e99df63685d44  modem.img.orig
ca597d1c2a0047ae076d7d61ed8f6168  mdlogger.bak

Usage
=====

 1. adb pull /custpack/modem/modem.img
 2. adb pull /system/bin/mdlogger
 3. bspatch modem.img patched.img modem.img.bsdiff && bspatch mdlogger mdlogger.bsdiff softsim
 4. adb push patched.img /data/local/tmp && adb push softsim /data/local/tmp
 5. Root your phone and install /data/local/tmp/patched.img over /custpack/modem/modem.img and /data/local/tmp/softsim over /system/bin/mdlogger
 (6. you might have to enable mdlogger start at boot in the MTK-engineering menue)

