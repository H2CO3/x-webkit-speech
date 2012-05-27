/**
 * tweak.m
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

#include <regex.h>
#include <substrate.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <AppSupport/CPDistributedMessagingCenter.h>
#include "common.h"

@class WebFrame, WebView, WebDataSource;

static id tabController;
static IMP _orig_1, _orig_2, _orig_3;

id _mod_1(id __self, SEL __cmd, CGRect frame, id tabDocument);
void _mod_2(id __self, SEL __cmd, id doc, BOOL error);
void _mod_3(id __self, SEL __cmd, WebView *webView, WebFrame *webFrame);

void XWKSDoDictation(NSString *numberString, WebView *webView);

/* The library constructor */
__attribute__((constructor))
static void init()
{
	Class tabClass, docClass;

	tabClass = objc_getClass("TabController");
	docClass = objc_getClass("TabDocument");

	MSHookMessageEx(tabClass, @selector(initWithFrame:tabDocument:),	
		(IMP)_mod_1, &_orig_1);
	MSHookMessageEx(tabClass, @selector(tabDocument:didFinishLoadingWithError:),
		(IMP)_mod_2, &_orig_2);
	MSHookMessageEx(docClass, @selector(webView:didChangeLocationWithinPageForFrame:),
		(IMP)_mod_3, &_orig_3);
}

/* This hook captures the TabController of Safari. */
id _mod_1(id __self, SEL __cmd, CGRect frame, id tabDocument)
{
	__self = _orig_1(__self, __cmd, frame, tabDocument);
	tabController = __self;
	return __self;
}

/* This is called when the page loading is done */
void _mod_2(id __self, SEL __cmd, id doc, BOOL error)
{
	id webView;
	NSString *payload;

	_orig_2(__self, __cmd, doc, error);

	/* Parse the HTML content and add the speech buttons */
	webView = [[[tabController activeTabDocument] browserView] webView];

	payload =
/**
 * Begin JavaScript payload
 * Essentially, we enumerate all <input> elements and give them an
 * ordinal number if they have their `x-webkit-speech' attribute set.
 * Then we insert a `Listen!' button before the input fields.
 * the xwksBeginSpeech function just redirects to our well-recognized
 * anchor URL, which we capture using a hook in the WebView.
 * Then we will know which text field to write the result to.
 * -------------------------------------------------------------------
 */
	      @"var inputs; \n\
		var input; \n\
		var btn; \n\
		\n\
		function xwksBeginSpeech(node) \n\
		{ \n\
			var num; \n\
			num = node.getAttribute(\"data-xwks\"); \n\
			window.location.href = \"#xwebkitspeech-\" + num; \n\
			/* This is needed to make it working when one \n\
			 * clicks on the same button multiple times. When \n\
			 * this happens, WebKit says 'Let us not go to the \n\
			 * same place twice', and refuses to call our \n\
			 * capturing callback. */ \n\
			window.location.href = \"#xwks-reset\"; \n\
		} \n\
		\n\
		inputs = document.getElementsByTagName(\"input\"); \n\
		/* Select the text inputs which have 'x-webkit-speech' */ \n\
		for (i = 0; i < inputs.length; i++) \n\
		{ \n\
			input = inputs[i]; \n\
			if (input.getAttribute(\"x-webkit-speech\") != null) \n\
			{ \n\
				btn = document.createElement(\"input\"); \n\
				btn.setAttribute(\"type\", \"button\"); \n\
				btn.setAttribute(\"value\", \"Listen!\"); \n\
				btn.setAttribute(\"data-xwks\", i); \n\
				btn.setAttribute(\"onclick\", \"xwksBeginSpeech(this);\"); \n\
				input.setAttribute(\"data-xwks\", i); \n\
				input.parentNode.insertBefore(btn, input); \n\
				i++; /* step over the button! */ \n\
			} \n\
		}";
/**
 * -------------------------------------------------------------------
 * End of JavaScript payload
 */
	/* Execute the script */
	[webView stringByEvaluatingJavaScriptFromString:payload];
}

/* This function captures the anchor redirects */
void _mod_3(id __self, SEL __cmd, WebView *webView, WebFrame *webFrame)
{
	NSRange prefixRange, numberRange;
	WebDataSource *dataSource;
	NSURL *url;
	NSString *urlString;
	NSString *numberString;
	int numberPos;

	/* Extract the text input's number from the URL hash */
	dataSource = [webFrame dataSource];
	url = [[dataSource request] URL];
	urlString = [url absoluteString];
	prefixRange = [urlString rangeOfString:@"#xwebkitspeech-"];

	/* If it's not found, it's none of our business, call %orig */
	if (prefixRange.location == NSNotFound)
	{
		_orig_3(__self, __cmd, webView, webFrame);
		return;
	}
	
	/* Else extract the number of the input, and start dication */
	numberPos = prefixRange.location + prefixRange.length;
	numberRange = NSMakeRange(numberPos, urlString.length - numberPos);
	numberString = [urlString substringWithRange:numberRange];

	XWKSDoDictation(numberString, webView);
}

void XWKSDoDictation(NSString *numberString, WebView *webView)
{
	NSString *payload;
	NSString *recognizedText;
	CPDistributedMessagingCenter *center;
	NSDictionary *response;

	/**
	 * Safari is in a sandbox that prohibits audio operations
	 * such as playing back audio with AVFoundation or recording it
	 * via Audio Queues (which libsprec does). So we have to make a
	 * dedicated server do the dirty work. We communicate between the
	 * two processes using CPDistributedMessagingCenter.
	 * TODO: this blocks and freezes the UI.
	 */
	center = [CPDistributedMessagingCenter centerNamed:XWKS_MACH_NAME];
	response = [center sendMessageAndReceiveReplyName:XWKS_RECORD_MESSAGE userInfo:NULL];
	recognizedText = [response objectForKey:XWKS_TEXT_KEY];

	payload = [[NSString alloc] initWithFormat:
/**
 * Begin JavaScript payload
 * We search the text input field by its number we assigned in
 * _mod_2, then we extract the spoken text from the messaging
 * center's response, and assign it to the text field.
 * -------------------------------------------------------------------
 */
	      @"var i; \n\
		var inputs; \n\
		var input; \n\
		\n\
		inputs = document.getElementsByTagName(\"input\"); \n\
		for (i = 0; i < inputs.length; i++) \n\
		{ \n\
			input = inputs[i]; \n\
			if (input.getAttribute(\"data-xwks\") != null) \n\
			{ \n\
				if (input.getAttribute(\"x-webkit-speech\") != null) \n\
				{ \n\
					if (input.getAttribute(\"data-xwks\") == %@) \n\
					{ \n\
						input.value = \"%@\"; \n\
						input.onwebkitspeechchange(null); \n\
						break; \n\
					} \n\
				 } \n\
			} \n\
		}", numberString, recognizedText];
/**
 * End of JavaScript payload
 * -------------------------------------------------------------------
 */

	/* Execute the script using the text just heard */
	[webView stringByEvaluatingJavaScriptFromString:payload];
	[payload release];
}

