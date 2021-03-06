/**
 * XWKSSettings.h
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

#ifndef __XWKSSETTINGS_H__
#define __XWKSSETTINGS_H__

#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@class PSSpecifier;

/**
 * Dummy superclass to make the compiler happy
 */
@interface PSListController: UIViewController {
	NSMutableDictionary *_cells;
	BOOL _cachesCells;
	id _table;
	NSArray *_specifiers;
	id _detailController;
	id _previousController;
	NSMutableArray *_controllers;
	NSMutableDictionary *_specifiersByID;
	BOOL _keyboardWasVisible;
	BOOL _showingSetupController;
	BOOL _selectingRow;
	NSString *_specifierID;
	PSSpecifier *_specifier;
	NSMutableArray *_groups;
	NSMutableArray *_bundleControllers;
	BOOL _bundlesLoaded;
	CGRect _cellRect;
	UIView *_alertSheet;
}

- (id)specifiers;
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;

@end

@interface XWKSSettings: PSListController
@end

#endif /* !__XWKSSETTINGS_H__ */

