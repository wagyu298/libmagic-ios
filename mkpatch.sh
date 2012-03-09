#!/bin/sh
# Make IOS patch file.
# Must run this script at top source directory
#

file=file-5.11
diff=$file-ios.diff

make distclean 2>/dev/null
find . -name .DS_Store -exec rm -f {} \;
rm -rf autom4te.cache ios/$diff

(cd ..; diff -r -u -N -p $file.orig $file > /tmp/$diff)
mv /tmp/$diff ios/$diff
