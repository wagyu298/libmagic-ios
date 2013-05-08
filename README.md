Description
===========

A library part of file(1) for iOS.  (The library also known as libmagic.)
Based file command (and magic file) was originally written by Ian Darwin (who still contributes occasionally) and is now maintained by a group of developers lead by Christos Zoulas. See http://darwinsys.com/file/ for more details about the file command.


Usage
=====

1. Download libmagic.framework.5.14.zip from [SourceForge.net](https://sourceforge.net/projects/libmagic-ios/files/).

2. Open or create your iOS application project with Xcode.

3.  Open summary tab of TARGETS section and add libmagic.framework to Linked Frameworks and Libraries.

4. Open libmagic.framework/Headers in source tree viewer of Xcode, drag `magic' file in that directory, and drop it to Copy bundle Resources in Build Phases tab of TARGET section.

5. Modify your AppDelegate source file. Add magic_ios_compile function call at didFinishLaunchingWithOptions of AppDelegate.m.
magic_ios_compile function compiled magic file to ~/.magic-ARCH/magic.cnf if it is missing (ARCH is the CPU architecture, such as .magic-armv7).
Be careful, magic_ios_compile function is multi-thread unsafe.

		- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
		{
		    // Override point for customization after application launch.
		    magic_ios_compile();
		    // ...
		}

6. Use libmagic.

		magic_t magic = magic_open(MAGIC_NONE);
		magic_load(magic, NULL);
		const char *filetype = magic_file(magic, path_of_file);
		NSLog(@"file type is %s", filetype);
		magic_close(magic);

Omit compiled magic
-------------------

You can use libmagic-ios without the compiled magic file.
In this case, you can omit the step 5 of the usage (magic_ios_compile function call at didFinishLaunchingWithOptions) and use the result of magic_ios_get_plain_magic function to the second argument of magic_load.

	magic_t magic = magic_open(MAGIC_NONE);
	magic_load(magic, magic_ios_get_plain_magic());
	// ...

magic_ios_get_plain_magic function returns the path of bundled plain magic file. See magicios.m for more details.


Building Framework
==================

Github repository includes the patch file of libmagic-ios.
You can generate libmagic-ios Xcode project from the patch file and original file utility tarball.

1. Clone or fetch Xcode project from libmagic-ios Github repository.

2. Download file-5.14.tar.gz from http://darwinsys.com/file/ and extract tarball to PROJECT_ROOT_DIR (like the following directory structure).

		libmagic-ios/
		    README
		    libmagic
		    ..
		    file-5.14

3. Apply file-5.14-ios.diff

		cd file-5.14
		patch -p1 < ../file-5.14-ios.diff

4. Open the libmagic.framework project file with Xcode. Change build scheme to libmagic.framework build it.


License
=======

libmagic-ios follows the license of file package, it licensed under modified BSD license.
See http://darwinsys.com/file/ for more details.
