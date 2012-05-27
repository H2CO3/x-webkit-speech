/**
 * XWKSServer.m
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

#include <sprec/sprec.h>
#include "XWKSServer.h"
#include "common.h"

#define XWKS_PREFS_FILE @"/var/mobile/Library/Preferences/org.h2co3.xwks.plist"

@implementation XWKSServer

- (id)init
{
	if ((self = [super init]))
	{
		center = [CPDistributedMessagingCenter centerNamed:XWKS_MACH_NAME];
		[center runServerOnCurrentThread];
		[center registerForMessageName:XWKS_RECORD_MESSAGE target:self selector:@selector(handleMessageNamed:userInfo:)];
	}
	return self;
}

- (NSDictionary *)handleMessageNamed:(NSString *)messageName userInfo:(NSDictionary *)userInfo
{
	NSMutableDictionary *response;
	NSDictionary *prefs;
	NSString *textAsString;
	const char *lang;
	char *recognizedText;
	struct sprec_wav_header *hdr;
	struct sprec_server_response *resp;
	char *flacbuf;
	int flacsize;
	int err;
	NSTimeInterval recTime;

	response = [NSMutableDictionary dictionary];
	[response setObject:@"(error)" forKey:XWKS_TEXT_KEY];

	if ([messageName isEqualToString:XWKS_RECORD_MESSAGE])
	{
		/* Load preferences */
		prefs = [NSDictionary dictionaryWithContentsOfFile:XWKS_PREFS_FILE];
		/* Quick-and-dirty speech recogition */
		hdr = sprec_wav_header_from_params(16000, 16, 2);
		if (hdr == NULL)
		{
			return response;
		}

		/* Read recording time in seconds from preferences */
		recTime = [[prefs objectForKey:@"ListeningDuration"] floatValue];
		err = sprec_record_wav(XWKS_WAV_FILE, hdr, recTime * 1000);
		if (err)
		{
			return response;
		}

		err = sprec_flac_encode(XWKS_WAV_FILE, XWKS_FLAC_FILE);
		if (err)
		{
			return response;
		}

		err = sprec_get_file_contents(XWKS_FLAC_FILE, &flacbuf, &flacsize);
		if (err)
		{
			return response;
		}

		/* Read language from preferences */
		lang = [[prefs objectForKey:@"Language"] UTF8String];
		resp = sprec_send_audio_data(flacbuf, flacsize, lang, hdr->sample_rate);
		free(hdr);
		if (resp == NULL)
		{
			return response;
		}

		recognizedText = sprec_get_text_from_json(resp->data);
		sprec_free_response(resp);
		if (recognizedText == NULL)
		{
			return response;
		}

		textAsString = [NSString stringWithFormat:@"%s", recognizedText];
		free(recognizedText);
		[response setObject:textAsString forKey:XWKS_TEXT_KEY];
	}
	return response;
}

@end

