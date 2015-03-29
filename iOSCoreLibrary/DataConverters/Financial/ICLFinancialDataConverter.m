//
//  ICLFinancialDataConverter.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 7/08/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLFinancialDataConverter.h"

#import "XMLWriter.h"
#import "ICLSGMLWriter.h"

NSString* kICLFinancialField_Type = @"ICL.Financial.Type";
NSString* kICLFinancialField_Date = @"ICL.Financial.Date";
NSString* kICLFinancialField_Amount = @"ICL.Financial.Amount";
NSString* kICLFinancialField_Description = @"ICL.Financial.Description";
NSString* kICLFinancialField_Category = @"ICL.Financial.Category";
NSString* kICLFinancialField_UniqueId = @"ICL.Financial.UniquieId";
NSString* kICLFinancialField_ItemPictureName = @"ICL.Financial.ItemPictureName";
NSString* kICLFinancialField_ReceiptPictureName = @"ICL.Financial.ReceiptPictureName";

NSString* kICLFinancialMetadata_CurrencyCode = @"ICL.Financial.CurrencyCode";
NSString* kICLFinancialMetadata_BankIdentifier = @"ICL.Financial.BankIdentifier";
NSString* kICLFinancialMetadata_AccountNumber = @"ICL.Financial.AccountNumber";
NSString* kICLFinancialMetadata_AccountType = @"ICL.Financial.AccountType";
NSString* kICLFinancialMetadata_ClosingBalance = @"ICL.Financial.ClosingBalance";

NSDateFormatter* currentLocalDateFormatter;
NSDateFormatter* dateFormatter_AUS;
NSDateFormatter* dateFormatter_USA;

@implementation ICLFinancialDataConverter

#pragma mark Public Entry Point

+ (BOOL) convertFinancialData:(NSArray*) data
                   outputFile:(NSString*) outputFilePath
                   exportType:(FinancialExportType) exportType
                     metadata:(NSDictionary*) metadata {
    // OFX requires very specific handling
    if (exportType == efetOFX_XML) {
        return [self convertFinancialData_OFX_XML:data outputFile:outputFilePath metadata:metadata];
    }
    else if (exportType == efetOFX_SGML) {
        return [self convertFinancialData_OFX_SGML:data outputFile:outputFilePath metadata:metadata];
    }
    
    // Create an empty file at the output path
    [@"" writeToFile:outputFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // open the output file
    NSFileHandle* outputFile = [NSFileHandle fileHandleForWritingAtPath:outputFilePath];
    
    if (!outputFile) {
        return NO;
    }
    
    BOOL result = NO;
    
    // Default local date formatter
    currentLocalDateFormatter = [[NSDateFormatter alloc] init];
    [currentLocalDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [currentLocalDateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    // Default local date formatter
    dateFormatter_AUS = [[NSDateFormatter alloc] init];
    [dateFormatter_AUS setDateFormat:@"dd/MM/yy"];
    
    // Default local date formatter
    dateFormatter_USA = [[NSDateFormatter alloc] init];
    [dateFormatter_USA setDateFormat:@"MM/dd/yy"];
    
    NSString* headerData = nil;
    switch(exportType) {
        case efetCSV:
            headerData = [self generateHeader_CSV];
            break;
        case efetQIF_AUS:
            headerData = [self generateHeader_QIF_AUS];
            break;
        case efetQIF_USA:
            headerData = [self generateHeader_QIF_USA];
            break;
        case efetOFX_SGML:
        case efetOFX_XML:
            assert(0);
            break;
    }
    
    [outputFile writeData:[headerData dataUsingEncoding:NSUTF8StringEncoding]];
    [outputFile writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Process each line item generating the corresponding data for it
    for (NSDictionary* lineItem in data) {
        FinancialExport_EntryType entryType = (FinancialExport_EntryType)[lineItem[kICLFinancialField_Type] integerValue];
        NSDate* date = lineItem[kICLFinancialField_Date];
        NSNumber* amount = lineItem[kICLFinancialField_Amount];
        NSString* description = lineItem[kICLFinancialField_Description];
        NSString* category = lineItem[kICLFinancialField_Category];
        NSString* itemPictureFileName = lineItem[kICLFinancialField_ItemPictureName];
        NSString* receiptPictureFileName = lineItem[kICLFinancialField_ReceiptPictureName];
        
        NSString* lineData = nil;

        switch(exportType) {
            case efetCSV:
                lineData = [self convertFinancialData_CSV:entryType
                                                     date:date
                                                   amount:amount
                                              description:description
                                                 category:category
                                      itemPictureFileName:itemPictureFileName
                                   receiptPictureFileName:receiptPictureFileName];
                break;
            case efetQIF_AUS:
                lineData = [self convertFinancialData_QIF_AUS:entryType
                                                         date:date
                                                       amount:amount
                                                  description:description
                                                     category:category];
                break;
            case efetQIF_USA:
                lineData = [self convertFinancialData_QIF_USA:entryType
                                                         date:date
                                                       amount:amount
                                                  description:description
                                                     category:category];
                break;
            case efetOFX_SGML:
            case efetOFX_XML:
                assert(0);
                break;
        }
        
        [outputFile writeData:[lineData dataUsingEncoding:NSUTF8StringEncoding]];
        [outputFile writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [outputFile closeFile];
    
    return result;
}

#pragma mark CSV and QIF Support

+ (NSString*) generateHeader_CSV {
    return @"\"Date\",\"Amount\",\"Name\",\"Category\",\"Item Picture Filename\",\"Receipt Picture Filename\"";
};

+ (NSString*) generateHeader_QIF_AUS {
    return @"!Type:Bank";
};

+ (NSString*) generateHeader_QIF_USA {
    return @"!Type:Bank";
};

+ (NSString*) convertFinancialData_CSV:(FinancialExport_EntryType) entryType
                                  date:(NSDate*) date
                                amount:(NSNumber*) amount
                           description:(NSString*) description
                              category:(NSString*) category
                   itemPictureFileName:(NSString*) itemPictureFileName
                receiptPictureFileName:(NSString*) receiptPictureFileName {
    return [@[[currentLocalDateFormatter stringFromDate:date],
              [NSString stringWithFormat:@"\"%1.2lf\"", entryType == efeetExpense ? -[amount doubleValue] : [amount doubleValue]],
              [NSString stringWithFormat:@"\"%@\"", description],
              [NSString stringWithFormat:@"\"%@\"", category],
              [NSString stringWithFormat:@"\"%@\"", itemPictureFileName],
              [NSString stringWithFormat:@"\"%@\"", receiptPictureFileName]] componentsJoinedByString:@","];
}

+ (NSString*) convertFinancialData_QIF_AUS:(FinancialExport_EntryType) entryType
                                      date:(NSDate*) date
                                    amount:(NSNumber*) amount
                               description:(NSString*) description
                                  category:(NSString*) category {
    return [@[[@"D" stringByAppendingString:[dateFormatter_AUS stringFromDate:date]],
              [NSString stringWithFormat:@"T%1.2lf", entryType == efeetExpense ? -[amount doubleValue] : [amount doubleValue]],
              [NSString stringWithFormat:@"P%@", description],
              @"^"] componentsJoinedByString:@"\r\n"];
}

+ (NSString*) convertFinancialData_QIF_USA:(FinancialExport_EntryType) entryType
                                      date:(NSDate*) date
                                    amount:(NSNumber*) amount
                               description:(NSString*) description
                                  category:(NSString*) category {
    return [@[[@"D" stringByAppendingString:[dateFormatter_USA stringFromDate:date]],
              [NSString stringWithFormat:@"T%1.2lf", entryType == efeetExpense ? -[amount doubleValue] : [amount doubleValue]],
              [NSString stringWithFormat:@"P%@", description],
              @"^"] componentsJoinedByString:@"\r\n"];
}

#pragma mark OFX SGML Support

+ (BOOL) convertFinancialData_OFX_SGML:(NSArray*) data outputFile:(NSString*) outputFilePath metadata:(NSDictionary*) metadata {
    // Create an empty file at the output path
    [@"" writeToFile:outputFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // open the output file
    NSFileHandle* outputFile = [NSFileHandle fileHandleForWritingAtPath:outputFilePath];
    
    if (!outputFile) {
        return NO;
    }
    
    ICLSGMLWriter* sgmlWriter = [[ICLSGMLWriter alloc] init];
    
    // Write the standard attributes for a v1.0.3 file
    [sgmlWriter writeAttribute:@"OFXHEADER" value:@"100"];
    [sgmlWriter writeAttribute:@"DATA" value:@"OFXSGML"];
    [sgmlWriter writeAttribute:@"VERSION" value:@"103"];
    [sgmlWriter writeAttribute:@"SECURITY" value:@"NONE"];
    [sgmlWriter writeAttribute:@"ENCODING" value:@"USASCII"];
    [sgmlWriter writeAttribute:@"CHARSET" value:@"1252"];
    [sgmlWriter writeAttribute:@"COMPRESSION" value:@"NONE"];
    [sgmlWriter writeAttribute:@"OLDFILEUID" value:@"NONE"];
    [sgmlWriter writeAttribute:@"NEWFILEUID" value:@"NONE"];
    
    // Start the OFX file
    [sgmlWriter writeStartElement:@"OFX"];
    
    [self generateOFXData:data ofxWriter:sgmlWriter metadata:metadata];
    
    // Convert the SGML to a string and write it to the output file
    [outputFile writeData:[[sgmlWriter toString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outputFile closeFile];
    
    return YES;
}

#pragma mark OFX XML Support

+ (BOOL) convertFinancialData_OFX_XML:(NSArray*) data outputFile:(NSString*) outputFilePath metadata:(NSDictionary*) metadata {
    // Create an empty file at the output path
    [@"" writeToFile:outputFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // open the output file
    NSFileHandle* outputFile = [NSFileHandle fileHandleForWritingAtPath:outputFilePath];
    
    if (!outputFile) {
        return NO;
    }
    
    XMLWriter* ofxWriter = [[XMLWriter alloc] init];
    
    [ofxWriter writeStartDocumentWithEncodingAndVersion:@"UTF-8" version:@"1.0"];
    
    [ofxWriter writeLinebreak];
    [ofxWriter write:@"<?OFX OFXHEADER=\"200\" VERSION=\"211\" SECURITY=\"NONE\" OLDFILEUID=\"NONE\" NEWFILEUID=\"NONE\"?>"];
    
    // Start the OFX file
    [ofxWriter writeStartElement:@"OFX"];
    
    [self generateOFXData:data ofxWriter:ofxWriter metadata:metadata];
    
    // Convert the XML to a string and write it to the output file
    [outputFile writeData:[[ofxWriter toString] dataUsingEncoding:NSUTF8StringEncoding]];

    [outputFile closeFile];
    
    return YES;
}

+ (void) generateOFXData:(NSArray*) data ofxWriter:(NSObject<XMLStreamWriter>*) ofxWriter metadata:(NSDictionary*) metadata {
    NSDateFormatter* ofxDateFormatter = [[NSDateFormatter alloc] init];
    [ofxDateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    
    NSDate* currentDate = [NSDate date];
    NSString* currentDateString = [ofxDateFormatter stringFromDate:currentDate];
    
    NSDate* endDate = [data firstObject][kICLFinancialField_Date];
    NSString* endDateString = [ofxDateFormatter stringFromDate:endDate];
    
    NSDate* startDate = [data lastObject][kICLFinancialField_Date];
    NSString* startDateString = [ofxDateFormatter stringFromDate:startDate];
    
    // Write the sign on response
    [ofxWriter writeStartElement:@"SIGNONMSGSRSV1"];
        [ofxWriter writeStartElement:@"SONRS"];
            [ofxWriter writeStartElement:@"STATUS"];
                [ofxWriter writeStartElement:@"CODE"];
                    [ofxWriter writeCharacters:@"0"];
                [ofxWriter writeEndElement]; // CODE
                [ofxWriter writeStartElement:@"SEVERITY"];
                    [ofxWriter writeCharacters:@"INFO"];
                [ofxWriter writeEndElement]; // SEVERITY
            [ofxWriter writeEndElement]; // STATUS
    
            [ofxWriter writeStartElement:@"DTSERVER"];
                [ofxWriter writeCharacters:currentDateString];
            [ofxWriter writeEndElement]; // DTSERVER
            
            [ofxWriter writeStartElement:@"LANGUAGE"];
                [ofxWriter writeCharacters:@"ENG"];
            [ofxWriter writeEndElement]; // LANGUAGE
        [ofxWriter writeEndElement]; // SONRS
    [ofxWriter writeEndElement]; // SIGNONMSGSRSV1
    
    // Write the bank transactions block
    [ofxWriter writeStartElement:@"BANKMSGSRSV1"];
        [ofxWriter writeStartElement:@"STMTTRNRS"];
        
            [ofxWriter writeStartElement:@"TRNUID"];
                [ofxWriter writeCharacters:@"1"];
            [ofxWriter writeEndElement]; // TRNUID
            
            [ofxWriter writeStartElement:@"STATUS"];
                [ofxWriter writeStartElement:@"CODE"];
                    [ofxWriter writeCharacters:@"0"];
                [ofxWriter writeEndElement]; // CODE
                [ofxWriter writeStartElement:@"SEVERITY"];
                    [ofxWriter writeCharacters:@"INFO"];
                [ofxWriter writeEndElement]; // SEVERITY
            [ofxWriter writeEndElement]; // STATUS
            
            [ofxWriter writeStartElement:@"STMTRS"];
            
                [ofxWriter writeStartElement:@"CURDEF"];
                    [ofxWriter writeCharacters:metadata[kICLFinancialMetadata_CurrencyCode]];
                [ofxWriter writeEndElement]; // CURDEF
                
                // Write the bank account information
                [ofxWriter writeStartElement:@"BANKACCTFROM"];
                    [ofxWriter writeStartElement:@"BANKID"];
                        [ofxWriter writeCharacters:metadata[kICLFinancialMetadata_BankIdentifier]];
                    [ofxWriter writeEndElement]; // BANKID
                    
                    [ofxWriter writeStartElement:@"ACCTID"];
                        [ofxWriter writeCharacters:metadata[kICLFinancialMetadata_AccountNumber]];
                    [ofxWriter writeEndElement]; // ACCTID
                    
                    [ofxWriter writeStartElement:@"ACCTTYPE"];
                        if ([metadata[kICLFinancialMetadata_AccountType] integerValue] == efeatChecking) {
                            [ofxWriter writeCharacters:@"CHECKING"];
                        }
                        else if ([metadata[kICLFinancialMetadata_AccountType] integerValue] == efeatSavings) {
                            [ofxWriter writeCharacters:@"SAVINGS"];
                        }
                        else if ([metadata[kICLFinancialMetadata_AccountType] integerValue] == efeatMoneyMarket) {
                            [ofxWriter writeCharacters:@"MONEYMRKT"];
                        }
                        else if ([metadata[kICLFinancialMetadata_AccountType] integerValue] == efeatLineOfCredit) {
                            [ofxWriter writeCharacters:@"CREDITLINE"];
                        }
                    [ofxWriter writeEndElement]; // ACCTTYPE
                [ofxWriter writeEndElement]; // BANKACCTFROM
                
                // Write the actual transactions
                [ofxWriter writeStartElement:@"BANKTRANLIST"];
                    [ofxWriter writeStartElement:@"DTSTART"];
                        [ofxWriter writeCharacters:startDateString];
                    [ofxWriter writeEndElement]; // DTSTART
                    [ofxWriter writeStartElement:@"DTEND"];
                        [ofxWriter writeCharacters:endDateString];
                    [ofxWriter writeEndElement]; // DTEND
                
                    for (NSDictionary* lineItem in data) {
                        FinancialExport_EntryType entryType = (FinancialExport_EntryType)[lineItem[kICLFinancialField_Type] integerValue];
                        NSDate* date = lineItem[kICLFinancialField_Date];
                        NSNumber* amount = lineItem[kICLFinancialField_Amount];
                        NSString* description = lineItem[kICLFinancialField_Description];
                        NSString* uniqueId = lineItem[kICLFinancialField_UniqueId];
                        
                        // Clamp the length of the description
                        description = [description substringToIndex:MIN(255, [description length])];
                     
                        [ofxWriter writeStartElement:@"STMTTRN"];
                            [ofxWriter writeStartElement:@"TRNTYPE"];
                                [ofxWriter writeCharacters:entryType == efeetIncome ? @"CREDIT" : @"DEBIT"];
                            [ofxWriter writeEndElement]; // TRNTYPE
                        
                            [ofxWriter writeStartElement:@"DTPOSTED"];
                                [ofxWriter writeCharacters:[ofxDateFormatter stringFromDate:date]];
                            [ofxWriter writeEndElement]; // DTPOSTED
                        
                            [ofxWriter writeStartElement:@"TRNAMT"];
                                [ofxWriter writeCharacters:[NSString stringWithFormat:@"%1.02lf", [amount doubleValue]]];
                            [ofxWriter writeEndElement]; // TRNAMT
                        
                            [ofxWriter writeStartElement:@"FITID"];
                                [ofxWriter writeCharacters:uniqueId];
                            [ofxWriter writeEndElement]; // FITID
                        
                            [ofxWriter writeStartElement:@"MEMO"];
                                [ofxWriter writeCharacters:description];
                            [ofxWriter writeEndElement]; // MEMO

                        [ofxWriter writeEndElement]; // STMTTRN
                    }
    
                [ofxWriter writeEndElement]; // BANKTRANLIST
                
                [ofxWriter writeStartElement:@"LEDGERBAL"];
                    [ofxWriter writeStartElement:@"BALAMT"];
                        [ofxWriter writeCharacters:[NSString stringWithFormat:@"%1.02lf", [metadata[kICLFinancialMetadata_ClosingBalance] doubleValue]]];
                    [ofxWriter writeEndElement]; // BALAMT
                    [ofxWriter writeStartElement:@"DTASOF"];
                        [ofxWriter writeCharacters:endDateString];
                    [ofxWriter writeEndElement]; // DTASOF
                [ofxWriter writeEndElement]; // LEDGERBAL
            
            [ofxWriter writeEndElement]; // STMTRS
        
        [ofxWriter writeEndElement]; // STMTTRNRS
    [ofxWriter writeEndElement]; // BANKMSGSRSV1
    
    // Close the OFX file
    [ofxWriter writeEndElement];
    [ofxWriter writeEndDocument];
}

@end
