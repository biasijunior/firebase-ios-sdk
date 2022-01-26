// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <XCTest/XCTest.h>

#include "Crashlytics/Crashlytics/Components/FIRCLSContext.h"
#import "Crashlytics/Crashlytics/Controllers/FIRCLSManagerData.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSExecutionIdentifierModel.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSInternalReport.h"
#import "Crashlytics/Crashlytics/Private/FIRCLSOnDemandModel_Private.h"
#import "Crashlytics/UnitTests/Mocks/FIRAppFake.h"
#import "Crashlytics/UnitTests/Mocks/FIRCLSMockExistingReportManager.h"
#import "Crashlytics/UnitTests/Mocks/FIRCLSMockOnDemandModel.h"
#import "Crashlytics/UnitTests/Mocks/FIRCLSMockReportUploader.h"
#import "Crashlytics/UnitTests/Mocks/FIRCLSMockSettings.h"
#import "Crashlytics/UnitTests/Mocks/FIRCLSTempMockFileManager.h"
#import "Crashlytics/UnitTests/Mocks/FIRMockGDTCoreTransport.h"
#import "Crashlytics/UnitTests/Mocks/FIRMockInstallations.h"

#import "Crashlytics/Crashlytics/DataCollection/FIRCLSDataCollectionArbiter.h"
#import "Crashlytics/Crashlytics/Settings/Models/FIRCLSApplicationIdentifierModel.h"

#define TEST_GOOGLE_APP_ID (@"1:632950151350:ios:d5b0d08d4f00f4b1")

@interface FIRCLSOnDemandModelTests : XCTestCase

@property(nonatomic, retain) FIRCLSMockOnDemandModel *onDemandModel;
@property(nonatomic, strong) FIRCLSMockExistingReportManager *existingReportManager;
@property(nonatomic, strong) FIRCLSManagerData *managerData;
@property(nonatomic, strong) FIRCLSDataCollectionArbiter *dataArbiter;
@property(nonatomic, strong) FIRCLSTempMockFileManager *fileManager;
@property(nonatomic, strong) FIRCLSMockReportUploader *mockReportUploader;
@property(nonatomic, strong) FIRCLSMockSettings *mockSettings;

@end

@implementation FIRCLSOnDemandModelTests

- (void)setUp {
  [super setUp];
  FIRSetLoggerLevel(FIRLoggerLevelMax);

  FIRCLSContextBaseInit();

  id fakeApp = [[FIRAppFake alloc] init];
  self.dataArbiter = [[FIRCLSDataCollectionArbiter alloc] initWithApp:fakeApp withAppInfo:@{}];

  self.fileManager = [[FIRCLSTempMockFileManager alloc] init];

  FIRMockInstallations *iid = [[FIRMockInstallations alloc] initWithFID:@"test_token"];

  FIRMockGDTCORTransport *mockGoogleTransport =
      [[FIRMockGDTCORTransport alloc] initWithMappingID:@"id" transformers:nil target:0];
  FIRCLSApplicationIdentifierModel *appIDModel = [[FIRCLSApplicationIdentifierModel alloc] init];
  _mockSettings = [[FIRCLSMockSettings alloc] initWithFileManager:self.fileManager
                                                       appIDModel:appIDModel];

  _managerData = [[FIRCLSManagerData alloc] initWithGoogleAppID:TEST_GOOGLE_APP_ID
                                                googleTransport:mockGoogleTransport
                                                  installations:iid
                                                      analytics:nil
                                                    fileManager:self.fileManager
                                                    dataArbiter:self.dataArbiter
                                                       settings:self.mockSettings];
  _existingReportManager =
      [[FIRCLSMockExistingReportManager alloc] initWithManagerData:self.managerData
                                                    reportUploader:self.mockReportUploader];
  [self.fileManager createReportDirectories];
  [self.fileManager
      setupNewPathForExecutionIdentifier:self.managerData.executionIDModel.executionID];
  _onDemandModel = [[FIRCLSMockOnDemandModel alloc] initWithOnDemandUploadRate:15
                                                                  baseExponent:5
                                                                  stepDuration:10];

  NSString *name = @"exception_model_report";
  NSString *reportPath = [self.fileManager.rootPath stringByAppendingPathComponent:name];
  [self.fileManager createDirectoryAtPath:reportPath];

  FIRCLSInternalReport *report =
      [[FIRCLSInternalReport alloc] initWithPath:reportPath
                             executionIdentifier:@"TEST_EXECUTION_IDENTIFIER"];
  FIRCLSContextInitialize(report, self.mockSettings, self.fileManager);
}

- (void)tearDown {
  self.onDemandModel = nil;
  [[NSFileManager defaultManager] removeItemAtPath:self.fileManager.rootPath error:nil];
  [super tearDown];
}

- (void)testIncrementsQueueWhenEventRecorded {
  FIRExceptionModel *exceptionModel = [self getTestExceptionModel];
  BOOL success = [self.onDemandModel recordOnDemandExceptionIfQuota:exceptionModel
                                          withDataCollectionEnabled:YES
                                         usingExistingReportManager:self.existingReportManager];
  [self.onDemandModel setQueueToEmpty];
  // Should record but not submit a report.
  XCTAssertTrue(success);
  XCTAssertEqual([self.onDemandModel getOrIncrementOnDemandEventCountForCurrentRun:NO], 1);
  XCTAssertEqual(self.onDemandModel.getQueuedOperationsCount, 1);
}

- (void)testCompliesWithDataCollectionOff {
  FIRExceptionModel *exceptionModel = [self getTestExceptionModel];
  BOOL success = [self.onDemandModel recordOnDemandExceptionIfQuota:exceptionModel
                                          withDataCollectionEnabled:NO
                                         usingExistingReportManager:self.existingReportManager];

  // Should record but not submit a report.
  XCTAssertTrue(success);
  // Currently, we don't count this as an occurred event.
  XCTAssertEqual([self.onDemandModel getOrIncrementOnDemandEventCountForCurrentRun:NO], 0);
  XCTAssertEqual([self contentsOfActivePath].count, 2);
}

- (void)testDropsEventIfNoQuota {
  [self.onDemandModel setQueueToFull];
  FIRExceptionModel *exceptionModel = [self getTestExceptionModel];
  BOOL success = [self.onDemandModel recordOnDemandExceptionIfQuota:exceptionModel
                                          withDataCollectionEnabled:NO
                                         usingExistingReportManager:self.existingReportManager];

  // Should return false when attempting to record an event and increment the count of dropped
  // events.
  XCTAssertFalse(success);
  XCTAssertEqual(self.onDemandModel.getQueuedOperationsCount, [self.onDemandModel getQueueMax]);
  XCTAssertEqual([self.onDemandModel getOrIncrementDroppedOnDemandEventCountForCurrentRun:NO], 1);
}

#pragma mark - Helpers
- (NSArray *)contentsOfActivePath {
  return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.fileManager.activePath
                                                             error:nil];
}

- (FIRExceptionModel *)getTestExceptionModel {
  NSArray *stackTrace = @[
    [FIRStackFrame stackFrameWithSymbol:@"CrashyFunc" file:@"AppLib.m" line:504],
    [FIRStackFrame stackFrameWithSymbol:@"ApplicationMain" file:@"AppleLib" line:1],
    [FIRStackFrame stackFrameWithSymbol:@"main()" file:@"main.m" line:201],
  ];
  NSString *name = @"FIRCLSOnDemandModelTestCrash";
  NSString *reason = @"Programmer made an error";

  FIRExceptionModel *exceptionModel = [FIRExceptionModel exceptionModelWithName:name reason:reason];
  exceptionModel.stackTrace = stackTrace;
  exceptionModel.isFatal = YES;
  exceptionModel.onDemand = YES;
  return exceptionModel;
}

@end
