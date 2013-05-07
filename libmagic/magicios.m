/*
 * Copyright (c) Masanori Mikawa 2012.
 * All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice immediately at the beginning of the file, without modification,
 *    this list of conditions, and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <sys/param.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include "magic.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
 * Returns path of the composed plain magic file.
 */
const char *
magic_ios_get_plain_magic(void)
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *magicPath = [mainBundle pathForResource:@"magic" ofType:nil];
    return [magicPath UTF8String];
}

static char *
get_hw_machine(void)
{
    int mib[2];
    size_t miblen, size;
    char *machine;

    miblen = 2;
    if (sysctlnametomib("hw.machine", mib, &miblen) == -1)
        return NULL;
    if (sysctl(mib, 2, NULL, &size, NULL, 0) == -1)
        return NULL;
    machine = malloc(size);
    if (machine == NULL)
        return NULL;
    if (sysctl(mib, 2, machine, &size, NULL, 0) == -1) {
        free(machine);
        return NULL;
    }
    return machine;
}

/*
 * Returns path of the compiled magic file.
 */
const char *
magic_ios_get_default_magic(void)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = nil;
    if ([paths count] <= 0)
        return NULL;
    documentPath = [paths objectAtIndex:0];

    char *machine = get_hw_machine();
    if (machine == NULL)
        return NULL;
    NSString *t = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@".magic-%s", machine]];
    free(machine);
    const char *ret = [[t stringByAppendingPathComponent:@"magic.mgc"] UTF8String];
    if (ret == nil)
        return NULL;
    return ret;
}

/*
 * Compile magic file.
 *
 * NOTE
 * Thread unsafe.
 */
int
magic_ios_compile(void)
{
    const char *default_path = magic_ios_get_default_magic();
    if (access(default_path, R_OK) == 0) {
        return 0;
    }

    const char *path = [[[NSString stringWithUTF8String:default_path] stringByDeletingLastPathComponent] UTF8String];
    struct stat sb;
    if (stat(path, &sb) == 0) {
        if (!S_ISDIR(sb.st_mode)) {
            errno = ENOTDIR;
            return -1;
        }
    } else {
        if (mkdir(path, 0777) == -1)
            return -1;
    }

    char owd[MAXPATHLEN];
    if (getwd(owd) == NULL) {
        return -1;
    }

    if (chdir(path) != 0) {
        return -1;
    }

    const char *magic_src = magic_ios_get_plain_magic();
    magic_t magic = magic_open(MAGIC_CHECK);
    if (magic == NULL)
        goto bad;
    if (magic_compile(magic, magic_src) != 0)
        goto bad;
    magic_close(magic);

    chdir(owd);
    return 0;

bad:
    chdir(owd);
    return -1;
}
