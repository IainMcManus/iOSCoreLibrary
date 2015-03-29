//
//  ICLFinancialDataConverter.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 7/08/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    efetCSV,        // Simple CSV export
    efetOFX_SGML,   // Open Financial Exchange File (SGML v1.0.3)
    efetOFX_XML,    // Open Financial Exchange File (XML v2.1.1)
    efetQIF_AUS,    // Quicken Interchange Format (AU Quicken 2004 and earlier)
    efetQIF_USA     // Quicken Interchange Format (US Quicken 2004 and earlier)
} FinancialExportType;

typedef enum {
    efeetIncome,
    efeetExpense
} FinancialExport_EntryType;

typedef enum {
    efeatChecking,
    efeatSavings,
    efeatMoneyMarket,
    efeatLineOfCredit
} FinancialExport_AccountType;

extern NSString* kICLFinancialField_Type;               // Expencts NSNumber for FinancialExport_EntryType
extern NSString* kICLFinancialField_Date;               // Expects NSDate
extern NSString* kICLFinancialField_Amount;             // Expects NSNumber
extern NSString* kICLFinancialField_Description;        // Expects NSString
extern NSString* kICLFinancialField_Category;           // Expects NSString
extern NSString* kICLFinancialField_UniqueId;           // Expects NSString
extern NSString* kICLFinancialField_ItemPictureName;    // Expects NSString (CSV Only)
extern NSString* kICLFinancialField_ReceiptPictureName; // Expects NSString (CSV Only)

extern NSString* kICLFinancialMetadata_CurrencyCode;    // Expects NSString
extern NSString* kICLFinancialMetadata_BankIdentifier;  // Expects NSString
extern NSString* kICLFinancialMetadata_AccountNumber;   // Expects NSString
extern NSString* kICLFinancialMetadata_AccountType;     // Expects NSNumber for FinancialExport_AccountType
extern NSString* kICLFinancialMetadata_ClosingBalance;  // Expects NSNumber

@interface ICLFinancialDataConverter : NSObject

+ (BOOL) convertFinancialData:(NSArray*) data
                   outputFile:(NSString*) outputFilePath
                   exportType:(FinancialExportType) exportType
                     metadata:(NSDictionary*) metadata;

@end
