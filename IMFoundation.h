/*
 *     Generated by class-dump 3.1.2.
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2007 by Steve Nygard.
 */

NSString *IMGetInlineImagePath();

struct OpaqueSecCertificateRef;

struct OpaqueSecKeyRef;

struct _DNSServiceRef_t;

struct _NSZone;

struct _TidyDoc {
    int _field1;
};

struct __CFDictionary;

struct __CFRunLoopSource;

struct __SCDynamicStore;

@class IMAttributedStringParserContext, IMXMLParserContext, IMXMLParserFrame;

/*
 * File: IMFoundation
 * Arch: Intel 80x86 (i386)
 *       Current version: 701.0.0, Compatibility version: 1.0.0
 */

@protocol FZSecureObject <NSObject>
- (void)setSecurityLevel:(int)fp8;
- (int)securityLevel;
@end

@interface BaseThreadedObject : NSObject
{
    id _delegate;
    BOOL _kill;
    BOOL _inProgress;
    float _timeout;
    NSTimer *_timeoutTimer;
    BOOL _done;
}

- (void)setTimeout:(double)fp8;
- (void)_clearTimeoutTimer;
- (void)_timeoutHit:(id)fp8;
- (void)_setTimeoutTimer;
- (id)init;
- (void)dealloc;
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (void)_threadedDoStart;
- (void)_doSendDone;
- (void)_workerThread;
- (void)_timedOut;
- (void)_workerThreadFinished;
- (void)startThread;
- (void)stopWatchingThread;
- (BOOL)inProgress;
- (BOOL)done;

@end

@interface DirectlyObservableObject : NSObject
{
    NSMutableArray *_observers;
}

- (id)init;
- (void)dealloc;
- (void)_objectDidPostNotification:(id)fp8;
- (void)addObserver:(id)fp8;
- (void)removeObserver:(id)fp8;
- (id)observers;
- (void)informObserversOfNotification:(id)fp8;

@end

@interface ExtendedOperation : NSOperation
{
    NSThread *_operationThread;
    NSString *_operationName;
    unsigned int _operationState;
    double _operationTimeout;
    NSMutableSet *_childOperations;
}

- (void)dealloc;
- (void)_setState:(unsigned int)fp8;
- (unsigned int)_maxChildOperationState;
- (unsigned int)_minChildOperationState;
- (void)_startThread;
- (void)start;
- (void)_threadedMain;
- (void)observeValueForKeyPath:(id)fp8 ofObject:(id)fp12 change:(id)fp16 context:(void *)fp20;
- (void)addChildOperation:(id)fp8;
- (void)createChildOperations;
- (void)didFinish;
- (void)setName:(id)fp8;
- (id)name;
- (void)setTimeout:(double)fp8;
- (double)timeout;
- (void)_stopWithState:(unsigned int)fp8;
- (void)_timeout;
- (void)fail;
- (void)cancel;
- (unsigned int)state;
- (BOOL)isConcurrent;
- (BOOL)isExecuting;
- (BOOL)isFinished;

@end

@interface FZInvocationQueue : NSObject
{
    NSMutableArray *_queue;
    NSMutableArray *_options;
    BOOL _holdQueue;
    id _target;
    id _delegate;
    double _dequeueRate;
}

- (id)init;
- (void)dealloc;
- (void)forwardInvocation:(id)fp8;
- (id)methodSignatureForSelector:(SEL)fp8;
- (void)setDelegate:(id)fp8;
- (id)delegate;
- (void)setTarget:(id)fp8;
- (id)target;
- (void)setDequeueRate:(double)fp8;
- (double)dequeueRate;
- (void)_stepQueueNotification:(id)fp8;
- (void)_holdQueueNotification:(id)fp8;
- (void)_releaseQueueNotification:(id)fp8;
- (void)_setQueueTimer;
- (BOOL)_invokeInvocation:(id)fp8;
- (void)_checkQueue;
- (unsigned int)_optionsForInvocation:(id)fp8;
- (int)_numberOfLimitedMessagesInQueue;
- (int)_maxQueueLimitSize;
- (BOOL)_acceptsOptions:(unsigned int)fp8;
- (BOOL)_replaceSimilarInvocation:(id)fp8;
- (BOOL)_insertInvocation:(id)fp8 options:(unsigned int)fp12;
- (int)_enqueueInvocation:(id)fp8 options:(unsigned int)fp12;
- (id)_dequeueInvocation;
- (void)removeAllInvocations;
- (void)invokeAll;
- (BOOL)isEmpty;
- (id)peek;

@end

@interface FZMessage : NSObject <NSCoding, NSCopying, FZSecureObject>
{
    NSString *_sender;
    NSDate *_time;
    NSAttributedString *_body;
    NSDictionary *_attributes;
    NSArray *_fileTransferGUIDs;
    int _flags;
    NSError *_error;
    NSString *_guid;
    NSString *_subject;
    NSString *_URL;
}

- (void)_cleanMessage;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)initWithCoder:(id)fp8;
- (void)encodeWithCoder:(id)fp8;
- (id)init;
- (id)initWithSender:(id)fp8 time:(id)fp12 body:(id)fp16 attributes:(id)fp20 fileTransferGUIDs:(id)fp24 flags:(int)fp28 error:(id)fp32 guid:(id)fp36;
- (void)dealloc;
- (id)URL;
- (id)subject;
- (id)sender;
- (id)time;
- (id)guid;
- (id)attributes;
- (int)flags;
- (BOOL)isAlert;
- (BOOL)isFinished;
- (BOOL)isEmpty;
- (BOOL)isPrepared;
- (id)error;
- (id)fileTransferGUIDs;
- (void)setSecurityLevel:(int)fp8;
- (int)securityLevel;
- (void)setSubject:(id)fp8;
- (void)setURL:(id)fp8;
- (void)setSender:(id)fp8;
- (void)setTime:(id)fp8;
- (void)setAttributes:(id)fp8;
- (void)setFileTransferGUIDs:(id)fp8;
- (void)setFlags:(int)fp8;
- (void)adjustIsEmptyFlag;
- (void)setError:(id)fp8;
- (void)setBody:(id)fp8;
- (id)body;

@end

@interface FZPair : NSObject <NSCopying>
{
    id _first;
    id _second;
}

+ (id)pairWithFirst:(id)fp8 second:(id)fp12;
- (id)initWithFirst:(id)fp8 second:(id)fp12;
- (id)first;
- (id)second;
- (void)dealloc;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (unsigned int)hash;
- (BOOL)isEqual:(id)fp8;

@end

@interface HFSFileManager : NSFileManager
{
}

+ (id)defaultManager;
+ (id)defaultHFSFileManager;
- (id)createTempFileBasedOnName:(id)fp8 hfsType:(unsigned long)fp12 hfsCreator:(unsigned long)fp16 hfsFlags:(unsigned short)fp20;
- (BOOL)existingPath:(id)fp8 toFSRef:(void *)fp12;
- (BOOL)existingPath:(id)fp8 toFSSpec:(void *)fp12;
- (id)attributesOfItemAtPath:(id)fp8 error:(id *)fp12;
- (BOOL)setAttributes:(id)fp8 ofItemAtPath:(id)fp12 error:(id *)fp16;
- (id)kindStringForFile:(id)fp8;
- (id)kindStringForFileWithName:(id)fp8 hfsType:(unsigned long)fp12 hfsCreator:(unsigned long)fp16 hfsFlags:(unsigned short)fp20;
- (id)displayNameOfFileWithName:(id)fp8 hfsFlags:(unsigned short)fp12;
- (id)MIMETypeOfPathExtension:(id)fp8;

@end

@interface IMAttributedStringParser : NSObject
{
    IMAttributedStringParserContext *_context;
}

+ (id)sharedInstance;
- (void)_preprocessWithContext:(id)fp8 string:(id *)fp12;
- (void)parseWithContext:(id)fp8;

@end

@interface IMAttributedStringParserContext : NSObject
{
    NSAttributedString *_inString;
}

- (id)initWithAttributedString:(id)fp8;
- (void)dealloc;
- (id)inString;
- (void)parserDidStart:(id)fp8;
- (void)parser:(id)fp8 foundAttributes:(id)fp12 inRange:(struct _NSRange)fp16;
- (void)parserDidEnd:(id)fp8;
- (BOOL)shouldPreprocess;
- (id)parser:(id)fp8 preprocessedAttributesForAttributes:(id)fp12 range:(struct _NSRange)fp16;

@end

@interface IMColor : NSObject <NSCoding, NSCopying>
{
    double _red;
    double _green;
    double _blue;
}

- (id)initWithRed:(double)fp8 green:(double)fp16 blue:(double)fp24;
- (id)initWithHTMLString:(id)fp8;
- (id)initWithCoder:(id)fp8;
- (void)encodeWithCoder:(id)fp8;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)description;
- (BOOL)isEqual:(id)fp8;
- (unsigned int)hash;
- (id)htmlString;
- (double)red;
- (double)green;
- (double)blue;

@end

@interface IMFileTransfer : NSObject <FZSecureObject>
{
    NSString *_guid;
    NSDate *_createdDate;
    NSDate *_startDate;
    int _transferState;
    BOOL _isIncoming;
    NSString *_filename;
    NSURL *_localURL;
    NSData *_localBookmark;
    unsigned int _hfsType;
    unsigned int _hfsCreator;
    unsigned short _hfsFlags;
    NSString *_otherPerson;
    NSString *_accountID;
    unsigned long long _currentBytes;
    unsigned long long _totalBytes;
    unsigned long long _averageTransferRate;
    BOOL _isDirectory;
    BOOL _shouldAttemptToResume;
    BOOL _wasSaved;
    BOOL _wasRegisteredAsStandalone;
    int _error;
    int _securityLevel;
    double _lastUpdatedInterval;
    double _lastAveragedInterval;
    unsigned long long _lastAveragedBytes;
}

- (void)dealloc;
- (id)_initWithGUID:(id)fp8 filename:(id)fp12 isDirectory:(BOOL)fp16 localURL:(id)fp20 account:(id)fp24 otherPerson:(id)fp28 totalBytes:(unsigned long long)fp32 hfsType:(unsigned long)fp40 hfsCreator:(unsigned long)fp44 hfsFlags:(unsigned short)fp48 isIncoming:(BOOL)fp52 securityLevel:(int)fp56;
- (void)_setAccount:(id)fp8 otherPerson:(id)fp12;
- (void)_setTransferState:(int)fp8;
- (void)_setStartDate:(id)fp8;
- (void)_setCurrentBytes:(unsigned long long)fp8 totalBytes:(unsigned long long)fp16;
- (void)_setAveragedTransferRate:(unsigned long long)fp8 lastAveragedInterval:(double)fp16 lastAveragedBytes:(unsigned long long)fp24;
- (void)_setError:(int)fp8;
- (void)_setLastUpdatedInterval:(double)fp8;
- (void)_setSecurityLevel:(int)fp8;
- (double)_lastUpdatedInterval;
- (double)_lastAveragedInterval;
- (unsigned long long)_lastAveragedBytes;
- (void)_clear;
- (void)_updateWithDictionaryRepresentation:(id)fp8;
- (id)_dictionaryRepresentation;
- (BOOL)canBeAccepted;
- (id)displayName;
- (BOOL)existsAtLocalPath;
- (id)localPath;
- (id)localURL;
- (id)localURLWithoutBookmarkResolution;
- (id)localBookmark;
- (void)_setLocalPath:(id)fp8;
- (void)_setLocalURL:(id)fp8;
- (id)guid;
- (id)startDate;
- (id)createdDate;
- (int)transferState;
- (BOOL)isIncoming;
- (id)filename;
- (unsigned long)hfsType;
- (unsigned long)hfsCreator;
- (unsigned short)hfsFlags;
- (id)accountID;
- (id)otherPerson;
- (unsigned long long)currentBytes;
- (unsigned long long)totalBytes;
- (unsigned long long)averageTransferRate;
- (BOOL)isDirectory;
- (BOOL)shouldAttemptToResume;
- (int)error;
- (void)setSecurityLevel:(int)fp8;
- (int)securityLevel;
- (BOOL)wasRegisteredAsStandalone;
- (void)setRegisteredAsStandalone:(BOOL)fp8;

@end

@interface IMFont : NSObject
{
    NSString *_name;
    NSNumber *_size;
    BOOL _isBold;
    BOOL _isItalic;
    NSString *_safeName;
}

- (id)initWithName:(id)fp8 size:(id)fp12 isBold:(BOOL)fp16 isItalic:(BOOL)fp20;
- (void)dealloc;
- (BOOL)isEqual:(id)fp8;
- (unsigned int)hash;
- (id)initWithCoder:(id)fp8;
- (void)encodeWithCoder:(id)fp8;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)description;
- (BOOL)isDefaultFont;
- (id)safeName;
- (id)name;
- (id)size;
- (BOOL)isBold;
- (BOOL)isItalic;

@end

@interface IMFromSuperParserContext : IMAttributedStringParserContext
{
    NSMutableArray *_inlinedFileTransferGUIDs;
    NSMutableArray *_standaloneFileTransferGUIDs;
}

- (id)initWithAttributedString:(id)fp8;
- (void)dealloc;
- (id)inlinedFileTransferGUIDs;
- (id)standaloneFileTransferGUIDs;
- (void)parserDidStart:(id)fp8;
- (void)parser:(id)fp8 foundAttributes:(id)fp12 inRange:(struct _NSRange)fp16;
- (void)parserDidStart:(id)fp8 bodyBackgroundColor:(id)fp12 bodyForegroundColor:(id)fp16 isRightToLeft:(BOOL)fp20;
- (void)parser:(id)fp8 foundAttributes:(id)fp12 inRange:(struct _NSRange)fp16 characters:(id)fp24 backgroundColor:(id)fp28 foregroundColor:(id)fp32 font:(id)fp36 link:(id)fp40 isUnderline:(BOOL)fp44;
- (void)parser:(id)fp8 foundAttributes:(id)fp12 inRange:(struct _NSRange)fp16 fileTransferGUID:(id)fp24 filename:(id)fp28 bookmark:(id)fp32 width:(id)fp36 height:(id)fp40;

@end

@interface IMXMLParser : NSObject <NSXMLParserDelegate>
{
    NSXMLParser *_parser;
    IMXMLParserContext *_context;
    IMXMLParserFrame *_topFrame;
    NSMutableArray *_otherFrames;
}

- (BOOL)parseWithContext:(id)fp8;
- (Class)defaultFrameClass;
- (id)prefix;
- (void)parser:(id)fp8 didStartElement:(id)fp12 namespaceURI:(id)fp16 qualifiedName:(id)fp20 attributes:(id)fp24;
- (void)parser:(id)fp8 didEndElement:(id)fp12 namespaceURI:(id)fp16 qualifiedName:(id)fp20;
- (void)parser:(id)fp8 foundCharacters:(id)fp12;
- (void)parser:(id)fp8 foundIgnorableWhitespace:(id)fp12;
- (void)parser:(id)fp8 parseErrorOccurred:(id)fp12;

@end

@interface IMHTMLParser : IMXMLParser
{
    struct _TidyDoc *_tidyDoc;
}

- (void)dealloc;
- (BOOL)parseWithContext:(id)fp8;
- (void)_setupTidy;
- (void)_teardownTidy;
- (void)_tidyContext:(id)fp8;

@end

@interface IMParserUtilities : NSObject
{
}

+ (id)newModifiedAttributesForAttributes:(id)fp8 lowercaseKeys:(BOOL)fp12 lowercaseValues:(BOOL)fp16;
+ (id)newAttributeValueStringFromString:(id)fp8;
+ (id)newEscapedStringFromString:(id)fp8 replaceSpacesWithString:(id)fp12 replaceNewlinesWithString:(id)fp16 replaceApostrophesWithString:(id)fp20 replaceQuotationMarksWithString:(id)fp24;
+ (id)newDictionaryFromCSSString:(id)fp8 lowercaseKeys:(BOOL)fp12;
+ (unsigned int)fontSizeFromCSSFontSizeValue:(id)fp8;

@end

@interface IMScreenSaverMonitor : NSObject
{
    NSMutableArray *_listeners;
    BOOL _screensaverActive;
    BOOL _screenLocked;
    BOOL _active;
}

+ (id)sharedMonitor;
- (id)init;
- (void)dealloc;
- (void)_screenLocked:(id)fp8;
- (void)_screenUnlocked:(id)fp8;
- (void)_screenSaverStopped:(id)fp8;
- (void)_screenSaverStarted:(id)fp8;
- (void)addListener:(id)fp8;
- (void)removeListener:(id)fp8;
- (BOOL)isScreenSaverActive;
- (BOOL)isScreenLocked;
- (void)setActive:(BOOL)fp8;
- (BOOL)isActive;

@end

@interface IMSuddenTermination : NSObject
{
}

+ (void)initialize;
+ (void)enable;
+ (void)disable;
+ (void)enableWithKey:(id)fp8;
+ (void)disableWithKey:(id)fp8;

@end

@interface IMSuperFormatUtilities : NSObject
{
}

+ (id)superFormatStringFromPlainTextString:(id)fp8;
+ (id)superFormatStringByRemovingFileTransfers:(id)fp8 fromString:(id)fp12;
+ (id)superFormatStringByAppendingFileTransfers:(id)fp8 toString:(id)fp12;

@end

@interface IMSuperToPlainParserContext : IMFromSuperParserContext
{
    NSMutableString *_plainString;
    BOOL _extractLinks;
}

- (id)initWithAttributedString:(id)fp8;
- (id)initWithAttributedString:(id)fp8 extractLinks:(BOOL)fp12;
- (void)dealloc;
- (id)plainString;
- (void)parser:(id)fp8 foundAttributes:(id)fp12 inRange:(struct _NSRange)fp16 characters:(id)fp24 backgroundColor:(id)fp28 foregroundColor:(id)fp32 font:(id)fp36 link:(id)fp40 isUnderline:(BOOL)fp44;

@end

@interface IMXMLParserContext : NSObject
{
    NSData *_inContentAsData;
}

- (id)initWithContent:(id)fp8;
- (id)initWithContentAsData:(id)fp8;
- (void)dealloc;
- (void)reset;
- (id)inContentAsData;
- (id)inContent;
- (void)setInContentAsData:(id)fp8;

@end

@interface IMToSuperParserContext : IMXMLParserContext
{
    unsigned int _underlineCount;
    unsigned int _boldCount;
    unsigned int _italicCount;
    NSMutableArray *_fontNameStack;
    NSMutableArray *_fontSizeStack;
    NSMutableArray *_linkStack;
    NSMutableArray *_backgroundColorStack;
    NSMutableArray *_foregroundColorStack;
    NSMutableDictionary *_currentAttributes;
    BOOL _didAddBodyAttributes;
    BOOL _isRightToLeft;
    IMColor *_backgroundColor;
    IMColor *_foregroundColor;
    NSMutableAttributedString *_body;
    NSMutableArray *_fileTransferGUIDs;
}

- (void)dealloc;
- (void)reset;
- (void)_initIvars;
- (void)_clearIvars;
- (void)_updateCurrentFont;
- (void)incrementBoldCount;
- (void)decrementBoldCount;
- (void)incrementItalicCount;
- (void)decrementItalicCount;
- (void)incrementUnderlineCount;
- (void)decrementUnderlineCount;
- (void)_pushValue:(id)fp8 ontoStack:(id)fp12 attributeName:(id)fp16;
- (void)_popValueFromStack:(id)fp8 attributeName:(id)fp12;
- (void)pushFontName:(id)fp8;
- (void)popFontName;
- (void)pushFontSize:(id)fp8;
- (void)popFontSize;
- (void)pushLink:(id)fp8;
- (void)popLink;
- (void)pushBackgroundColor:(id)fp8;
- (void)popBackgroundColor;
- (void)pushForegroundColor:(id)fp8;
- (void)popForegroundColor;
- (void)setBackgroundColor:(id)fp8;
- (void)setForegroundColor:(id)fp8;
- (void)setRightToLeft:(BOOL)fp8;
- (void)appendString:(id)fp8;
- (void)appendFileTransferWithGUID:(id)fp8;
- (void)appendInlineImageWithGUID:(id)fp8 filename:(id)fp12 width:(int)fp16 height:(int)fp20;
- (id)backgroundColor;
- (id)foregroundColor;
- (id)fileTransferGUIDs;
- (id)body;

@end

@interface IMXMLParserFrame : NSObject
{
}

- (void)parser:(id)fp8 context:(id)fp12 didStartElement:(id)fp16 namespaceURI:(id)fp20 qualifiedName:(id)fp24 attributes:(id)fp28;
- (void)parser:(id)fp8 context:(id)fp12 didEndElement:(id)fp16 namespaceURI:(id)fp20 qualifiedName:(id)fp24;
- (void)parser:(id)fp8 context:(id)fp12 foundCharacters:(id)fp16;
- (void)parser:(id)fp8 context:(id)fp12 foundIgnorableWhitespace:(id)fp16;

@end

@interface IMToSuperParserFrame : IMXMLParserFrame
{
}

- (void)parser:(id)fp8 context:(id)fp12 didStartElement:(id)fp16 namespaceURI:(id)fp20 qualifiedName:(id)fp24 attributes:(id)fp28;
- (void)parser:(id)fp8 context:(id)fp12 didEndElement:(id)fp16 namespaceURI:(id)fp20 qualifiedName:(id)fp24;
- (void)parser:(id)fp8 context:(id)fp12 foundCharacters:(id)fp16;
- (void)parser:(id)fp8 context:(id)fp12 foundIgnorableWhitespace:(id)fp16;

@end

@interface KeychainPasswordFetcher : BaseThreadedObject
{
    NSString *_service;
    NSString *_username;
    NSString *_password;
}

- (id)initWithUsername:(id)fp8 service:(id)fp12;
- (void)dealloc;
- (void)_workerThread;
- (void)_workerThreadFinished;

@end

@interface NSArray (FezAdditions)
- (BOOL)containsObjectIdenticalTo:(id)fp8;
- (int)indexOfObject:(id)fp8 matchingComparison:(SEL)fp12;
- (BOOL)containsObject:(id)fp8 matchingComparison:(SEL)fp12;
- (id)arrayByApplyingSelectorWithValues:(SEL)fp8 toObject:(id)fp12;
- (id)arrayByFilteringOutBySelector:(SEL)fp8 withObject:(id)fp12;
@end

@interface NSAttributedString (FezAdditions)
- (BOOL)attribute:(id)fp8 existsInRange:(struct _NSRange)fp12;
- (id)trimmedString;
@end

@interface NSBundle (FezBundleHelpers)
- (id)_cachedMainBundleResourcePath;
@end

@interface NSData (FezAdditions)
+ (id)dataWithHexString:(id)fp8;
+ (id)dataWithRandomBytes:(unsigned int)fp8;
- (id)hexStringOfBytes:(char *)fp8 withLength:(int)fp12;
- (id)hexString;
@end

@interface NSData (FezSecurityAdditions)
+ (id)dataWithCertificate:(struct OpaqueSecCertificateRef *)fp8;
+ (id)dataWithPublicKey:(struct OpaqueSecKeyRef *)fp8;
- (id)CRAM_MD5DataWithKey:(id)fp8;
- (id)CRAM_MD5HexStringWithKey:(id)fp8;
- (id)SHA1Data;
- (id)SHA1HexString;
- (struct OpaqueSecCertificateRef *)certificateFromData;
- (struct OpaqueSecKeyRef *)publicKeyFromData;
@end

@interface NSDate (FezAdditions)
+ (id)dateWithISOFormatString:(id)fp8;
- (int)dayComponent;
- (int)daysAgo;
@end

@interface NSDateFormatter (RTLAdditions)
+ (BOOL)isDateFormatRTL;
@end

@interface NSDictionary (FezAdditions)
+ (id)_dictionaryWithData:(id)fp8 isPlist:(BOOL)fp12 allowedClasses:(id)fp16;
+ (id)dictionaryWithPlistData:(id)fp8;
+ (id)dictionaryWithArchiveData:(id)fp8 allowedClasses:(id)fp12;
+ (id)dictionaryWithArchiveData:(id)fp8;
- (id)keysOfChangedEntriesComparedTo:(id)fp8;
- (id)plistData;
- (id)archiveData;
- (id)dictionaryFromChanges:(id)fp8;
@end

@interface NSDictionary (HFSFileAttributes)
- (unsigned short)fileHFSFlags;
- (unsigned long long)fileHFSResourceForkSize;
@end

@interface NSError (FezAdditions)
+ (id)genericErrorWithFile:(const char *)fp8 function:(const char *)fp12 lineNumber:(int)fp16;
@end

@interface NSFileManager (FezAdditions)
- (BOOL)_isPathOnMissingVolume:(id)fp8;
- (BOOL)makeDirectoriesInPath:(id)fp8 mode:(int)fp12;
- (id)uniqueFilename:(id)fp8 atPath:(id)fp12 ofType:(id)fp16;
- (id)createUniqueDirectoryWithName:(id)fp8 atPath:(id)fp12 ofType:(id)fp16;
- (BOOL)_moveItemAtPath:(id)fp8 toPath:(id)fp12 uniquePath:(id *)fp16 error:(id *)fp20 asCopy:(BOOL)fp24;
- (BOOL)moveItemAtPath:(id)fp8 toPath:(id)fp12 uniquePath:(id *)fp16 error:(id *)fp20;
- (BOOL)copyItemAtPath:(id)fp8 toPath:(id)fp12 uniquePath:(id *)fp16 error:(id *)fp20;
@end

@interface NSMutableArray (FezAdditions)
+ (id)nonRetainingArray;
@end

@interface NSMutableAttributedString (FezAdditions)
- (void)trimWhitespace;
- (void)replaceNewlinesWithSpaces;
- (void)replaceAttribute:(id)fp8 value:(id)fp12 withValue:(id)fp16;
- (void)removeCharactersWithAttribute:(id)fp8;
@end

@interface NSMutableDictionary (IMUtils_Additions)
+ (id)nonRetainingDictionary;
@end

@interface NSMutableString (FezAdditions)
- (void)replaceNewlinesWithSpaces;
@end

@interface NSNumber (FezAdditions)
- (id)localizedString;
@end

@interface NSObject (FZSecureObject)
- (void)postSecurityLevelChangeFrom:(int)fp8 to:(int)fp12;
- (BOOL)isSecurityEnabled;
- (BOOL)isSecurityNormal;
@end

@interface NSObject (FezAdditions)
- (BOOL)isNull;
@end

@interface NSString (AppleAOSHelpers)
- (id)dotMacDomain;
- (BOOL)hasDotMacSuffix;
- (id)stripDotMacSuffixIfPresent;
@end

@interface NSString (FezAdditions)
- (BOOL)isEqualToIgnoringCase:(id)fp8;
- (BOOL)isDirectory;
- (unsigned int)hexValue;
- (unsigned int)unsignedIntValue;
- (int)localizedCompareToString:(id)fp8;
- (BOOL)localizedHasPrefix:(id)fp8 caseSensitive:(BOOL)fp12;
- (id)trimmedString;
- (id)stringByRemovingURLEscapes;
- (id)stringByAddingURLEscapes;
- (id)urlFromString;
- (id)stringWithDefaultServerIfNeeded:(id)fp8;
- (BOOL)isPhone;
- (BOOL)isICQ;
- (BOOL)isICQorPhone;
- (id)stringByResolvingAndStandardizingPath;
- (id)commaSeparatedComponents;
- (struct _NSRange)rangeOfNewlineInRange:(struct _NSRange)fp8;
- (id)stringByRemovingWhitespace;
- (id)uniqueSavePath;
- (id)stringByStrippingControlCharacters;
- (id)stringByRemovingCharactersFromSet:(id)fp8;
@end

@interface NSString (IMGUIDAdditions)
+ (id)stringGUID;
@end

@interface NSString (IMSessionThreadNameStringAdditions)
- (id)sessionIDFromIMThreadName;
- (id)IMThreadNameFromPersonIDWithSession:(id)fp8;
- (id)personIDFromThreadName;
- (id)IMThreadNameFromChatIDWithSession:(id)fp8;
- (id)chatIDFromIMThreadName;
- (unsigned short)threadPrefix;
- (id)stringWithThreadPrefix:(unsigned short)fp8;
- (id)stringByRemovingThreadPrefix:(unsigned short)fp8;
- (BOOL)isThreadNameEqualToThreadName:(id)fp8;
- (BOOL)isThreadNameChatThread;
- (id)stringByStrippingSessionFromThreadName;
- (BOOL)roomNameIsProbablyAutomaticallyGenerated;
@end

@interface NetworkChangeNotifier : NSObject
{
    struct __SCDynamicStore *_store;
    struct __CFRunLoopSource *_runLoopSource;
    NSMutableArray *_listeners;
    BOOL _pendingPost;
    BOOL _asleep;
    struct _DNSServiceRef_t *_dnsService;
    struct __CFRunLoopSource *_dnsServiceRunLoopSource;
    NSString *_myIP;
    NSArray *_myIPs;
}

+ (id)sharedNotifier;
+ (BOOL)enableNotifications;
+ (void)disableNotifications;
- (void)_delayPost;
- (void)_clearIPCache;
- (void)_cancelPost;
- (void)_cancelAndRepostIfNecessary;
- (void)_sendNotification;
- (void)_goingToSleep:(id)fp8;
- (void)_wakeUp:(id)fp8;
- (BOOL)_listenForChanges;
- (id)init;
- (void)addListener:(id)fp8;
- (void)removeListener:(id)fp8;
- (void)dealloc;
- (id)myIPAddresses;
- (id)myIPAddress;
- (unsigned short)nextAvailablePort;
- (struct _DNSServiceRef_t *)sharedDNSService;
- (void)_clearSharedDNSService;
- (struct __SCDynamicStore *)getDynamicStore;

@end

@interface SystemProxySettingsFetcher : NSObject
{
    id _delegate;
    NSString *_host;
    unsigned short _port;
    int _proxyProtocol;
    NSString *_proxyHost;
    unsigned short _proxyPort;
    NSString *_proxyAccount;
    NSString *_proxyPassword;
}

- (void)_callProxySettingsDelegateMethod;
- (void)_callAccountSettingsDelegateMethod;
- (void)_getProxyAccountAndPasswordFromKeychain;
- (void)_takeProxySettingsFromDictionary:(struct __CFDictionary *)fp8;
- (id)initWithHost:(id)fp8 port:(unsigned short)fp12 delegate:(id)fp16;
- (id)initWithProxyProtocol:(int)fp8 proxyHost:(id)fp12 proxyPort:(unsigned short)fp16 delegate:(id)fp20;
- (void)setDelegate:(id)fp8;
- (void)retrieveProxySettings;
- (void)retrieveProxyAccountSettings;
- (void)dealloc;

@end

@interface URLFetcher : NSObject
{
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    id _delegate;
    BOOL _useCache;
}

- (void)dealloc;
- (id)initWithDelegate:(id)fp8;
- (void)setDelegate:(id)fp8;
- (id)connection:(id)fp8 willCacheResponse:(id)fp12;
- (void)cancel;
- (void)sendURLRequest:(id)fp8;
- (void)connection:(id)fp8 didReceiveResponse:(id)fp12;
- (void)connection:(id)fp8 didReceiveData:(id)fp12;
- (void)connection:(id)fp8 didFailWithError:(id)fp12;
- (void)connectionDidFinishLoading:(id)fp8;
- (void)setAllowsCachedResults:(BOOL)fp8;

@end

