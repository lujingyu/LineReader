//
//  LineReaderAppDelegate.m
//  LineReader
//
//  Created by Tobias Preuss on 05.10.10.
//  Copyright 2010 Tobias Preuss. All rights reserved.
//

#import "LineReaderAppDelegate.h"
#import "DirectoryReader.h"
#import "FileReader.h"
#import "NSFileHandleAdditions.h"


/**
	An application delegate.
 */
@implementation LineReaderAppDelegate


/**
	Initializes an application delegate object.
	@returns An initialized LineReaderAppDelegate object or nil if the object could not be created.
 */
- (id)init {

	self = [super init];
	if (self != nil) {
		m_sourcePath = [NSString stringWithFormat:@"/tmp/"];
		m_maxNumLines = [NSNumber numberWithInt:3];
		m_selectedReadMode = [NSNumber numberWithInt:BACKWARDS];
		m_printLines = [NSNumber numberWithBool:YES];
		m_status = [NSString stringWithFormat:@"Application started."];		
		m_directoryListing = nil;
	}
	return self;
}


// -----------------------------------------------------------------------------
// Properties.
// -----------------------------------------------------------------------------


@synthesize window = m_window;
@synthesize maxNumLines = m_maxNumLines;
@synthesize sourcePath = m_sourcePath;
@synthesize selectedReadMode = m_selectedReadMode;
@synthesize printLines = m_printLines;
@synthesize status = m_status;




// -----------------------------------------------------------------------------
// Event functions.
// -----------------------------------------------------------------------------


/**
	Sent by the default notification center after the application 
	has been launched and initialized but before it has received 
	its first event.
	@param aNotification A notification named NSApplicationDidFinishLaunchingNotification.
 */
- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
}


/**
	The function is called whenever lines should be read.
	@param sender The object calling this method.
 */
- (IBAction)readLinesRequested:(id)sender {
	
	[self processSource];
//	[self processSourceWithFileHandle];
}



// -----------------------------------------------------------------------------
// Private functions.
// -----------------------------------------------------------------------------


/**
	Reads a various number of lines from multiple files as 
	found in the source path. The lines can be read forwards 
	or backwards from the file.
	The function used the extended NSFileHandle class.
 */
- (void)processSourceWithFileHandle {
	
	int lineCount;
	NSTimeInterval processingStarted = [NSDate timeIntervalSinceReferenceDate];
	
	DirectoryReader* directoryReader = [[DirectoryReader alloc] initWithPath:m_sourcePath];
	if (!directoryReader) {
		return;
	}

	if ([directoryReader readDirectory:&m_directoryListing]) {
		
		for (NSString* path in m_directoryListing) {
			lineCount = 0;
			
			NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
			if (!fileHandle) {
				NSLog(@"FileHandle could not be initialized with path: %@. Skipping path.", path); /* DEBUG LOG */
				continue;
			}
			
			NSString* line = nil;
			NSMutableArray* lines = [NSMutableArray arrayWithCapacity:[m_maxNumLines integerValue]];
			
			if ([m_printLines boolValue]) {
				
				switch ([m_selectedReadMode intValue]) {
					case FORWARDS:
						[lines removeAllObjects];
						while ((line = [fileHandle readLine])) {
							if (line) {
								lineCount++;
								// Drop first line cause it might be uncomplete.
								if (lineCount > 1) {
									[lines addObject:line];
								}
								if (lineCount >= [m_maxNumLines intValue]) {
									break;
								}
							}
							else {
								NSLog(@"NSFileHandle readLine did not return a line."); /* DEBUG LOG */
							}
						}
						
						NSLog(@"lines: %@", lines); /* DEBUG LOG */
						break;
						
					case BACKWARDS:
						[lines removeAllObjects];
						while ((line = [fileHandle readLineBackwards])) {
							if (line) {
								lineCount++;
								
								NSLog(@"line: %@", line); /* DEBUG LOG */
								
								// Drop first line cause it might be uncomplete.
//								if (lineCount > 1) {
									[lines insertObject:line atIndex:0];
//								}
								if (lineCount >= [m_maxNumLines intValue]) {
									break;
								}
							}
							else {
								NSLog(@"NSFileHandle readLineBackwards did not return a line."); /* DEBUG LOG */
							}
						}
						
						NSLog(@"lines: %@", lines); /* DEBUG LOG */
						break;

					default:
						NSLog(@"Warning: LineReaderAppDelegate processSourceWithFileHandle. Undefined default state."); /* DEBUG LOG */
						break;
				} // switch
			} // printLines
			
			
			
			else {
				
				NSLog(@"printLines = %d, This option is not implemented yet.", [m_printLines boolValue]); /* DEBUG LOG */
			}

			
			// Immediately free file handle resource.
			[fileHandle closeFile];
			fileHandle = nil;
			
		} // for
	} // read directory
	
	NSTimeInterval processingEnded = [NSDate timeIntervalSinceReferenceDate];
	
	if ([m_selectedReadMode intValue] == FORWARDS)
		self.status = [NSString stringWithFormat:@"Processing %d lines forwards took %f seconds.", lineCount, (processingEnded - processingStarted)];
	else
		self.status = [NSString stringWithFormat:@"Processing %d lines backwards took %f seconds.", lineCount, (processingEnded - processingStarted)];
	
}


/**
	Reads a various number of lines from multiple files as 
	found in the source path. The lines can be read forwards 
	or backwards from the file.
 */
- (void)processSource {

	int lineCount;
	NSTimeInterval processingStarted = [NSDate timeIntervalSinceReferenceDate];
	
	DirectoryReader* directoryReader = [[DirectoryReader alloc] initWithPath:m_sourcePath];
	if (!directoryReader) {
		return;
	}
	
	if ([directoryReader readDirectory:&m_directoryListing]) {
		
		for (NSString* path in m_directoryListing) {
			NSLog(@"File: %@", path); /* DEBUG LOG */
			lineCount = 0;
			FileReader* fileReader = [[FileReader alloc] initWithFilePath:path];
			if (!fileReader) {
				return;
			}
			
			NSString* line = nil;
			NSMutableArray* lines = [NSMutableArray arrayWithCapacity:[m_maxNumLines integerValue]];
			
			
			if ([m_printLines boolValue]) {
				// Print lines to console.
				switch ([m_selectedReadMode intValue]) {
					case FORWARDS:
						[fileReader setCurrentOffset:34];
						[lines removeAllObjects];
						while ((line = [fileReader readLine])) {
							lineCount++;							
							uint fromBytePos = [fileReader currentOffset] - [line length];
							uint tillBytePos = [fileReader currentOffset] - 1;
							NSLog(@"%3.d: (%d - %d) %@", lineCount, fromBytePos, tillBytePos, line);
							NSLog(@"CURRENTOFFSET = %llu", [fileReader currentOffset]); /* DEBUG LOG */

							// Drop first line cause it might be uncomplete.
							if (lineCount > 1) {
								[lines addObject:line];
							}

							if (lineCount >= [m_maxNumLines intValue]) {
								break;
							}
						}				
						break;
					case BACKWARDS:
						[fileReader setCurrentIndent:34];
						while ((line = [fileReader readLineBackwards])) {
							lineCount++;							
							uint fromBytePos = [fileReader currentIndent];
							uint tillBytePos = fromBytePos + [line length];
							NSLog(@"%3.d: (%d - %d) %@", lineCount, fromBytePos, tillBytePos, line);
							NSLog(@"CURRENTINDENT = %llu", [fileReader currentIndent]); /* DEBUG LOG */
							
							[lines insertObject:line atIndex:0];
							if (lineCount >= [m_maxNumLines intValue]) {
								break;
							}
						}					
						break;
					default:
						NSLog(@"Warning: Read mode not set correctly."); /* DEBUG LOG */
						break;
				}				
			}
			else {
				// Do not print lines to console.				
				switch ([m_selectedReadMode intValue]) {
					case FORWARDS:
						[lines removeAllObjects];
						while ((line = [fileReader readLine])) {
							lineCount++;
							if (lineCount >= [m_maxNumLines intValue]) {
								break;
							}
						}				
						break;
					case BACKWARDS:
						[lines removeAllObjects];
						while ((line = [fileReader readLineBackwards])) {
							lineCount++;
							if (lineCount >= [m_maxNumLines intValue]) {
								break;
							}
						}					
						break;
					default:
						NSLog(@"Warning: Read mode not set correctly."); /* DEBUG LOG */
						break;
				}				
				
			}
			// Immediately free file handle resource.
			[fileReader closeFileHandle];
		}		
	}
	
	NSTimeInterval processingEnded = [NSDate timeIntervalSinceReferenceDate];
	
	if ([m_selectedReadMode intValue] == FORWARDS)
		self.status = [NSString stringWithFormat:@"Processing %d lines forwards took %f seconds.", lineCount, (processingEnded - processingStarted)];
	else
		self.status = [NSString stringWithFormat:@"Processing %d lines backwards took %f seconds.", lineCount, (processingEnded - processingStarted)];
					
}

@end
