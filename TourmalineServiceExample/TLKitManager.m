//
//  TLKitManager.m
//  TourmalineServiceExample
//
//  Created by Brian Dennis Vega Hidalgo on 28-10-19.
//  Copyright © 2019 Brian Dennis Vega Hidalgo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TLKit/CKContextKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "TLKitManager.h"
#import <CoreLocation/CoreLocation.h>

static NSString *const API_KEY  = @"API_KEY";
// used to store the last monitoring mode to user defaults
static NSString *const MONITORING_MODE_KEY = @"MONITORING_MODE_KEY";

@interface TLKitManager () <CLLocationManagerDelegate>
@end

@implementation TLKitManager

- (void)begin:(NSString *) username {
  
  NSUserDefaults *standardUserDefaults = NSUserDefaults.standardUserDefaults;
  [standardUserDefaults registerDefaults:@{ MONITORING_MODE_KEY: @(CKMonitoringModeManual) }];
  [standardUserDefaults synchronize];
  
  self.clLocationManager = [[CLLocationManager alloc] init];
  self.clLocationManager.delegate = self;
  self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
  self.clLocationManager.distanceFilter = 5.0f;
  self.tsDrives = [NSMutableArray array];
  self.cUsername = username;
  self.mode = CKMonitoringModeManual;
  
}

- (CKMonitoringMode)mode {
  return [NSUserDefaults.standardUserDefaults integerForKey:MONITORING_MODE_KEY];
}

- (void)setMode:(CKMonitoringMode)mode {
  NSUserDefaults *standardUserDefaults = NSUserDefaults.standardUserDefaults;
  [standardUserDefaults setInteger:mode forKey:MONITORING_MODE_KEY];
  [standardUserDefaults synchronize];
}

- (NSString *)monitoringModeString {
  switch (self.mode) {
    case CKMonitoringModeAutomatic:
      return @"Automatic Monitoring";
    case CKMonitoringModeManual:
      return @"Manual Monitoring";
    case CKMonitoringModeUnmonitored:
      return @"Not monitoring";
    default:
      break;
  }
  return @"?";
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
  
  NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
  NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
  
  [self.tsDrives addObject: [NSString stringWithFormat: @"%f,%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude]];
}

- (void)stopTLKit {
  
  // destroy engine
  [CKContextKit destroyWithResultToQueue:dispatch_get_main_queue()
                             withHandler:^(BOOL __unused successful, NSError * _Nullable error) {
                               if (error) {
                                 NSLog(@"Failed to stop TLKit with error: %@", error);
                                 return;
                               }
                             }];
}

- (void)startTLKit {
  
  if (CKContextKit.isInitialized) {
    NSLog(@"TLKit is already started! (mode: %@)",
          self.monitoringModeString);
    return;
  }
  
  NSString* hashedId = [self hashedId:self.cUsername];
  // initializes engine with automatic drive detection
  [CKContextKit initWithApiKey:API_KEY
                      hashedId:hashedId
                          mode:CKMonitoringModeManual
                 launchOptions:nil
             withResultToQueue:dispatch_get_main_queue()
                   withHandler:^(BOOL __unused successful,
                                 NSError * _Nullable error) {
                     if (error) {
                       NSLog(@"Failed to start TLKit: %@", error);
                       return;
                     }
                     
                     NSLog(successful ? @"TLKit Started successfully" : @"TLKit Started with error");
                   }];
}

- (NSMutableArray *)getDrives {
  if(self.tsDrives == nil){
    self.tsDrives = [NSMutableArray array];
  }
  return self.tsDrives;
}

- (NSString *)hashedId:(NSString *)uniqueId {
  NSData *strData = [uniqueId dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableData *sha = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
  
  CC_SHA256(strData.bytes,
            (unsigned int)strData.length,
            (unsigned char*)sha.mutableBytes);
  
  NSMutableString* hexStr = [NSMutableString string];
  
  [sha enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
    for (NSUInteger i = 0; i < byteRange.length; ++i) {
      [hexStr appendFormat:@"%02x", ((uint8_t*)bytes)[i]];
    }
  }];
  return [hexStr uppercaseString];
  
}


//DRIVES/TRIPS IMPLEMENTATION


- (void)startDriveMonitoring {
  
  // initialize CKActivityManager
  NSLog(@"<< Initializing Activity Manager >>");
  self.activityManager = CKActivityManager.new;
  
  NSLog(@"<< Initializing Updating Location >>");
  [self.clLocationManager startUpdatingLocation];
  
  // start drive monitoring
  NSLog(@"<< Starting Drive Monitoring >>");
  __weak __typeof__(self) weakSelf = self;
  [self.activityManager
   listenForDriveEventsToQueue:dispatch_get_main_queue()
   withHandler:^(CKActivityEvent * _Nullable evt,
                 NSError * _Nullable error) {
     
     // handle error
     if (error) {
       NSLog(@"Failed to register lstnr: %@", error);
       return;
     }
     
     NSLog(@"New CKActivityEvent: %@", evt);
     if (!weakSelf) return;
     
     // update the drives once the activity is finalized
     if (evt.type == CKActivityEventFinalized) {
       [weakSelf queryDrives];
     } else {
       [weakSelf mergeDrivesWithEvent:evt];
     }
   }];
}

- (void)stopDriveMonitoring {
  // stop Drive Monitoring
  [self.activityManager stopListeningForDriveEvents];
  NSLog(@"<< Stopped Drive monitoring >>");
  
  [self.clLocationManager stopUpdatingLocation];
  NSLog(@"<< Stopped Updating Location >>");
}

- (void)mergeDrivesWithEvent:(CKActivityEvent *)event {
  NSMutableArray<CKDrive *> *drives = self.drives.mutableCopy;
  
  // new event drive id
  NSUUID *uuid = event.activity.id;
  
  // lookup for the drive
  CKDrive *drive = nil;
  for (CKDrive *d in drives) {
    if ([d.id isEqual:uuid]) {
      drive = d;
      break;
    }
  }
  
  // removes the drive if found
  if (drive) {
    [drives removeObject:drive];
  }
  
  // add the last event's drive
  [drives addObject:(CKDrive *)event.activity];
  
  // sort the drives
  NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO];
  [drives sortUsingDescriptors:@[sort]];
  self.drives = drives.copy;
  
  // query active manual drives before reloading
  [self queryActiveDrives];
}

- (void)queryDrives {
  
  __weak __typeof__(self) weakSelf = self;
  // query drives since last week with a limit of max 50 results
  [self.activityManager queryDrivesFromDate:NSDate.distantPast
                                     toDate:NSDate.distantFuture
                                  withLimit:50
                                    toQueue:dispatch_get_main_queue()
                                withHandler:^(NSArray<__kindof CKActivity *> * _Nullable activities, NSError * _Nullable err) {
                                  
                                  // handle error
                                  if (err) {
                                    NSLog(@"Query Drives failed with error: %@", err);
                                    return;
                                  }
                                  
                                  NSLog(@"Query Drives result: %@", activities);
                                  if (!weakSelf) return;
                                  
                                  weakSelf.drives = activities;
                                  [weakSelf queryActiveDrives];
                                  
                                }];
}

- (void)queryActiveDrives {
  // only query manual active drives if in manual drive detection mode
  
  __weak __typeof__(self) weakSelf = self;
  [self.activityManager queryManualTripstoQueue:dispatch_get_main_queue()
                                    withHandler:^(NSArray<__kindof CKActivity *> * _Nullable activities, NSError * _Nullable err) {
                                      // handle error
                                      if (err) {
                                        NSLog(@"Query Active Manual Drives failed with error: %@", err);
                                        return;
                                      }
                                      
                                      NSLog(@"Query Active Manual Drives result: %@", activities);
                                      if (!weakSelf) return;
                                      
                                      weakSelf.active = activities;
                                    }];
}




@end
