/*
 * IMRenderingFoundation.h
 *
 * Copyright (c) 2007-2009 Kent Sutherland
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@interface TranscriptStyleController : NSObject
{
}

+ (Class)documentFragmentProviderClass;
+ (Class)instantMessageFragmentProviderClass;
+ (Class)messageContainerFragmentProviderClass;
+ (Class)messageBodyFragmentProviderClass;
+ (Class)emoticonFragmentProviderClass;
+ (Class)emoteFragmentProviderClass;
+ (Class)fileTransferFragmentProviderClass;
+ (void)setFileTransferFragmentProviderClass:(Class)arg1;
+ (Class)datestampFragmentProviderClass;
+ (Class)timestampFragmentProviderClass;
+ (Class)errorFragmentProviderClass;
+ (Class)systemMessageFragmentProviderClass;
+ (Class)headerFragmentProviderClass;
+ (Class)statusChangeFragmentProviderClass;
+ (Class)announcementFragmentProviderClass;
+ (Class)markFragmentProviderClass;
+ (Class)personNameFragmentProviderClass;
+ (Class)buddyIconFragmentProviderClass;
+ (Class)dateFragmentProviderClass;
+ (Class)knockKnockFragmentProviderClass;
+ (Class)timestampResolverClass;
- (id)documentFragmentProvider;
- (id)instantMessageFragmentProvider;
- (id)messageContainerFragmentProvider;
- (id)messageBodyFragmentProvider;
- (id)emoticonFragmentProvider;
- (id)emoteFragmentProvider;
- (id)fileTransferFragmentProvider;
- (id)datestampFragmentProvider;
- (id)timestampFragmentProvider;
- (id)errorFragmentProvider;
- (id)systemMessageFragmentProvider;
- (id)headerFragmentProvider;
- (id)statusChangeFragmentProvider;
- (id)announcementFragmentProvider;
- (id)markFragmentProvider;
- (id)personNameFragmentProvider;
- (id)buddyIconFragmentProvider;
- (id)dateFragmentProvider;
- (id)knockKnockFragmentProvider;
- (id)timestampResolver;
- (id)initWithWebView:(id)arg1;
- (id)webView;
- (id)window;
- (void)transcriptDidLoad;
- (void)dealloc;
- (void)beginChanges;
- (void)_rebuildCSSRuleMap;
- (BOOL)_firstLoadApplyQueuedCSSRules;
- (int)changeCount;
- (void)_applyChanges;
- (void)applyCurrentChanges;
- (void)endChanges;
- (void)setDOMCSSRule:(id)arg1 forSelector:(id)arg2;
- (id)DOMCSSRuleForSelector:(id)arg1;
- (BOOL)_applyQueuedCSSRules;
- (void)applyCSSSelector:(id)arg1 property:(id)arg2 value:(id)arg3 priority:(id)arg4;
- (void)applyCSSSelector:(id)arg1 property:(id)arg2 value:(id)arg3;
- (void)applyCSSSelector:(id)arg1 fromDictionary:(id)arg2;
- (void)clearCSSSelector:(id)arg1;
- (void)clearCSSSelector:(id)arg1 forProperties:(id)arg2;
- (void)_setNeedsRebuild;
- (void)beginBatchViewChange;
- (BOOL)endBatchViewChange;
- (void)makeSystemMessagesVisible;
- (void)makeSystemMessagesInvisible;
- (void)hideTimestamps;
- (void)showTimestamps;
- (void)hideMessageContent;
- (void)showMessageContent;
- (void)makeTimestampsInvisible;
- (void)makeTimestampsVisible;
- (void)hideScrollbars;
- (void)showScrollbars;
- (void)showSmileys;
- (void)hideSmileys;
- (void)showPictures;
- (void)hidePictures;
- (void)showNames;
- (void)hideNames;
- (void)hideBackground;
- (void)showBackground;
- (void)makeNotSelectable;
- (void)makeSelectable;
- (void)setBackgroundColor:(id)arg1;
- (void)setBackgroundImage:(id)arg1;
- (void)setLastTimestamp:(id)arg1;
- (void)appendInstantMessage:(id)arg1;
- (void)removeInstantMessage:(id)arg1;
- (void)replaceInstantMessage:(id)arg1 withMessage:(id)arg2;
- (NSRect)previousMessageRect;
- (NSRect)screenBoundsForElement:(id)arg1;
- (NSRect)screenBoundsForElementID:(id)arg1;
- (NSRect)messagePreviewBounds;
- (NSRect)rectOfMessage:(id)arg1;
- (NSRect)boundsOfMessage:(id)arg1;
- (id)lastMessage;
- (id)DOM;
- (id)body;
- (id)head;
- (id)style;
- (id)subnodesOfMessage:(id)arg1 tagName:(id)arg2;
- (void)emptyBody;
- (void)removeNodeAndChildren:(id)arg1;
- (void)removeChildren:(id)arg1;
- (void)bodyFinishLayout;
- (void)setWatchMessageAddressing:(BOOL)arg1;
- (void)setRemoteUserOverrideFormatting:(BOOL)arg1;
- (void)setAllowsPlugins:(BOOL)arg1;
- (BOOL)allowsPlugins;
- (void)localUserSetBackgroundColor:(id)arg1;
- (void)localUserSetFontColor:(id)arg1;
- (void)localUserSetFont:(id)arg1;
- (void)remoteUserSetBackgroundColor:(id)arg1;
- (void)remoteUserSetFontColor:(id)arg1;
- (void)remoteUserSetFont:(id)arg1;
- (void)personInfoChanged:(id)arg1;
- (void)personPictureChanged:(id)arg1;
- (void)retainFragment:(id)arg1;
- (void)adjustDateFragmentsForTimeChange;
- (void)dateFormatDidChange;
- (void)rebuildMessageBodies:(id)arg1;
- (void)setLastCommittedMessage:(id)arg1;
- (id)lastCommittedMessage;
- (id)ddResultsAdded;
- (void)didAddDDResults:(id)arg1 forMessage:(id)arg2;
- (id)ddResultsRemoved;
- (void)clearDDResultsRemoved;
- (void)didRemoveDDResults:(id)arg1 forMessage:(id)arg2;
- (void)ddMessageNeedsSync:(id)arg1;
- (id)ddMessagesNeedingSync;
- (void)clearDDResults;

@end
