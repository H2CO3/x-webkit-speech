/**
 * server.m
 * "x-webkit-speech" attribute for MobileSafari
 *
 * Copyright (C) 2012, Árpád Goretity
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *	* Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *	* Redistributions in binary form must reproduce the above copyright
 *	  notice, this list of conditions and the following disclaimer in the
 *	  documentation and/or other materials provided with the distribution.
 *	* Neither the name of Árpád Goretity nor the names of other
 *	  contributors may be used to endorse or promote products derived
 *	  from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL ÁRPÁD GORETITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <Foundation/Foundation.h>
#include "XWKSServer.h"

int main()
{
	pid_t pid, sid;
	XWKSServer *server;

	pid = fork();
	if (pid < 0)
	{
		/* fork() failed */
		exit(EXIT_FAILURE);
	}
	if (pid > 0)
	{
		/* We're the parent */
		exit(EXIT_SUCCESS);
	}

	/* Else we're the child */
	umask(0);

	/* Not to become zombie process */
	sid = setsid();
	if (sid < 0)
	{
		/* sid() failed */
		exit(EXIT_FAILURE);
	}

	if (chdir("/") < 0)
	{
		/* chdir() failed */
		exit(EXIT_FAILURE);
	}

	/* daemons don't require a terminal */
	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	/* Here we actually initialize the essence of your daemon */
	server = [[XWKSServer alloc] init];

	/* And we set up an infinite loop using proper Cocoa methods */
	NSDate *now = [[NSDate alloc] init];
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:now interval:30.0 target:NULL selector:NULL userInfo:NULL repeats:YES];
	[now release];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
	[runLoop run];

	/* This is never reached */
	[timer release];
	[server release];
	[pool release];

	return 0;
}

