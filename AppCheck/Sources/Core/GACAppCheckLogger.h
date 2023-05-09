/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "FirebaseCore/Extension/FirebaseCoreInternal.h"

extern FIRLoggerService kFIRLoggerAppCheck;

FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeUnknown;

// GACAppCheck.m
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeProviderFactoryIsMissing;
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeProviderIsMissing;

// GACAppCheckAPIService.m
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeUnexpectedHTTPCode;

// GACAppCheckDebugProvider.m
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageDebugProviderIncompleteFIROptions;
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageDebugProviderFailedExchange;

// GACAppCheckDebugProviderFactory.m
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeDebugToken;

// GACDeviceCheckProvider.m
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageDeviceCheckProviderIncompleteFIROptions;

// GACAppAttestProvider.m
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeAppAttestNotSupported;
FOUNDATION_EXPORT NSString *const kFIRLoggerAppCheckMessageCodeAttestationRejected;

void GACAppCheckDebugLog(NSString *messageCode, NSString *message, ...);