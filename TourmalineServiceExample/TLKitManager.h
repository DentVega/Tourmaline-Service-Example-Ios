//
//  TLKitManager.h
//  TourmalineServiceExample
//
//  Created by Brian Dennis Vega Hidalgo on 28-10-19.
//  Copyright © 2019 Brian Dennis Vega Hidalgo. All rights reserved.
//

#ifndef TLKitManager_h
#define TLKitManager_h

#import <TLKit/CKActivityManager.h>
#import <TLKit/CKActivityEvent.h>
#import <TLKit/CKDrive.h>

@interface TLKitManager: NSObject
//CONFIG START TLKIT
@property (strong, nonatomic) NSString *cUsername;
@property (strong, nonatomic) CLLocationManager *clLocationManager;
@property (assign, nonatomic) CKMonitoringMode mode;
//CONFIG MANUAL DRIVES/TRIPS
@property (strong, nonatomic) CKActivityManager  *activityManager;
@property (strong, nonatomic) NSMutableArray *tsDrives;
@property (strong, nonatomic) NSArray<CKDrive *> *drives;
@property (strong, nonatomic) NSArray<CKDrive *> *active;
//TLKIT
- (NSString *)monitoringModeString;
- (void)begin:(NSString *) username;
- (void)startTLKit;
- (void)stopTLKit;

//MANUAL DRIVES/TRIPS
- (void)startDriveMonitoring;
- (void)stopDriveMonitoring;
- (void)mergeDrivesWithEvent:(CKActivityEvent *)event;
- (void)queryDrives;
- (void)queryActiveDrives;
- (NSMutableArray *)getDrives;

@end

#endif /* TLKitManager_h */
