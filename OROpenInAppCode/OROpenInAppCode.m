//
//  OROpenInAppCode.m
//  OROpenInAppCode
//
//  Created by Orta on 30/01/2014.
//    Copyright (c) 2014 Orta Therox. All rights reserved.
//
// Totally inspired by https://github.com/inquisitiveSoft/AJKExtendedOpening/blob/master/Classes/AJKExtendedOpening.m

#import "OROpenInAppCode.h"

static OROpenInAppCode *sharedPlugin;

@interface OROpenInAppCode()
@end

@implementation OROpenInAppCode

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init])
    if(!self) return nil;

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(setup)
     name:NSApplicationDidFinishLaunchingNotification
     object:nil];
    

    return self;
}


- (void)setup
{
    // Add menu bar items for the 'Show Project in Finder' and 'Open Project in Terminal' actions
    NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTitle:@"File"] submenu];
    NSInteger desiredMenuItemIndex = [fileMenu indexOfItemWithTitle:@"Open with External Editor"];
    
    if(fileMenu && (desiredMenuItemIndex >= 0)) {
        NSMenuItem *openWithExternalEditorMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open Project in AppCode" action:@selector(openInAppCode:) keyEquivalent:@"a"];
        [openWithExternalEditorMenuItem setTarget:self];
        [openWithExternalEditorMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
        [fileMenu insertItem:openWithExternalEditorMenuItem atIndex:desiredMenuItemIndex];
    } else if([NSApp mainMenu]) {
        NSLog(@"OROpenInAppCode Xcode plugin: Couldn't find an 'Open with External Editor' item in the File menu");
    }
    else{
        NSLog(@"OROpenInAppCode Xcode plugin: Couldn't get menu");
    }
}

- (void)openInAppCode:(id)sender
{
    NSURL *currentFileURL = [self currentProjectURL];
    if(currentFileURL) {
        NSArray *bundleIds = @[@"com.jetbrains.AppCode-EAP", @"com.jetbrains.AppCode"];
        for (NSString *bundleIdentifier in bundleIds)
        {
            if ([[NSWorkspace sharedWorkspace] openURLs:@[currentFileURL]
                            withAppBundleIdentifier:bundleIdentifier
                                            options:0
                     additionalEventParamDescriptor:nil
                                  launchIdentifiers:nil])
            {
                break;
            }
        }
    }
}

- (NSURL *)currentProjectURL
{
    for (NSDocument *document in [NSApp orderedDocuments]) {
        @try {
            //        _workspace(IDEWorkspace) -> representingFilePath(DVTFilePath) -> relativePathOnVolume(NSString)
            NSURL *workspaceDirectoryURL = [[[document valueForKeyPath:@"_workspace.representingFilePath.fileURL"] URLByDeletingLastPathComponent] filePathURL];

            if(workspaceDirectoryURL) {
                return workspaceDirectoryURL;
            }
        }

        @catch (NSException *exception) {
            NSLog(@"OROpenInAppCode Xcode plugin: Raised an exception while asking for the documents '_workspace.representingFilePath.relativePathOnVolume' key path: %@", exception);
        }
    }

    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
