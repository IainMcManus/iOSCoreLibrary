//
//  ICLSGMLWriter.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 12/08/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLSGMLWriter.h"

@implementation ICLSGMLWriter {
    NSMutableString* buffer;
    NSMutableArray* elementStack;
    NSMutableArray* elementNeedsClose;
}

- (id)init {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    buffer = [[NSMutableString alloc] init];
    elementStack = [[NSMutableArray alloc] init];
    elementNeedsClose = [[NSMutableArray alloc] init];
    
    return self;
}

- (NSString*) sanitiseString:(NSString*) rawString {
    NSString* cleanedString = [rawString copy];
    
    cleanedString = [cleanedString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    cleanedString = [cleanedString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    cleanedString = [cleanedString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    
    return cleanedString;
}

#pragma mark XMLStreamWriter Protocol Support

- (void) writeStartDocument {
    // Intentionally empty
}

- (void) writeStartDocumentWithVersion:(NSString*)version {
    // Intentionally empty
}

- (void) writeStartDocumentWithEncodingAndVersion:(NSString*)encoding version:(NSString*)version {
    // Intentionally empty
}

- (void) writeStartElement:(NSString *)localName {
    if ([elementNeedsClose count] > 0) {
        elementNeedsClose[[elementNeedsClose count] - 1] = @(YES);
    }
    
    [elementStack addObject:localName];
    [elementNeedsClose addObject:@(NO)];
    
    if ([buffer length] > 0) {
        [buffer appendString:@"\r\n"];
    }
    
    [buffer appendFormat:@"<%@>", localName];
}

- (void) writeEndElement {
    if ([elementStack count] > 0) {
        if ([[elementNeedsClose lastObject] boolValue]) {
            if ([buffer length] > 0) {
                [buffer appendString:@"\r\n"];
            }
            
            [buffer appendFormat:@"</%@>", [elementStack lastObject]];
        }
        
        [elementStack removeLastObject];
        [elementNeedsClose removeLastObject];
    }
}

- (void) writeEndElement:(NSString *)localName {
    // Intentionally empty
}

- (void) writeEmptyElement:(NSString *)localName {
    // Intentionally empty
}

- (void) writeEndDocument {
    // Intentionally empty
}

- (void) writeAttribute:(NSString *)localName value:(NSString *)value {
    if ([buffer length] > 0) {
        [buffer appendString:@"\r\n"];
    }
    
    [buffer appendFormat:@"%@:%@", localName, [self sanitiseString:value]];
}

- (void) writeCharacters:(NSString*)text {
    [buffer appendFormat:@"%@", [self sanitiseString:text]];
}

- (void) writeComment:(NSString*)comment {
    // Intentionally empty
}

- (void) writeProcessingInstruction:(NSString*)target data:(NSString*)data {
    // Intentionally empty
}

- (void) writeCData:(NSString*)cdata {
    // Intentionally empty
}

- (NSMutableString*) toString {
    return buffer;
}

- (NSData*) toData {
    return [buffer dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) flush {
}

- (void) close {
    buffer = [[NSMutableString alloc] init];
    elementStack = [[NSMutableArray alloc] init];
    elementNeedsClose = [[NSMutableArray alloc] init];
}

@end
