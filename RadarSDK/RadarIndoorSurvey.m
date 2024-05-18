#import "RadarIndoorSurvey.h"

@implementation RadarIndoorSurvey

// in init, set isScanningMutex to false
- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"setting self.isScanningMutex to NO");
        self.isScanningMutex = NO;
    }
    return self;
}

- (void)start:(NSString *)placeLabel forLength:(int)surveyLengthSeconds withKnownLocation:(CLLocation *)knownLocation isWhereAmIScan:(BOOL)isWhereAmIScan withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler {
    NSLog(@"start called with placeLabel: %@, surveyLengthSeconds: %d, isWhereAmIScan: %d", placeLabel, surveyLengthSeconds, isWhereAmIScan);

    // if isScanningMutex is true, throw error
    NSLog(@"self.isScanningMutex: %d", self.isScanningMutex);
    if (self.isScanningMutex) {
        completionHandler(@"error: scan was already in progress");
        return;
    }

    // set isScanningMutex to true
    self.isScanningMutex = YES;

    self.placeLabel = placeLabel;
    self.completionHandler = completionHandler;
    self.bluetoothReadings = [NSMutableArray new];

    self.isWhereAmIScan = isWhereAmIScan;

    // set fresh uuid on self.scanId
    self.scanId = [[NSUUID UUID] UUIDString];

    // if isWhereAmIScan but no knownLocation, throw error
    // as we are expecting to have been called from track
    if (isWhereAmIScan && !knownLocation) {
        NSLog(@"Error: start called with isWhereAmIScan but no knownLocation");
        return;
    } else if(isWhereAmIScan && knownLocation) {
        // if isWhereAmIScan and knownLocation,
        // set self.locationAtTimeOfSurveyStart to knownLocation
        self.locationAtTimeOfSurveyStart = knownLocation;

        [self kickOffMotionAndBluetooth:surveyLengthSeconds];
    } else if(!isWhereAmIScan) {        
        // get location at time of survey start
        [Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation *location, NSArray<RadarEvent *> *events, RadarUser *user) {
            NSLog(@"location: %f, %f", location.coordinate.latitude, location.coordinate.longitude);
            // print location object as is
            NSLog(@"%@", location);

            // set self.locationAtTimeOfSurveyStart to location
            self.locationAtTimeOfSurveyStart = location;

            [self kickOffMotionAndBluetooth:surveyLengthSeconds];
        }];
    }
}

// expose the isScanningMutex in a getter
- (BOOL)isScanning {
    return self.isScanningMutex;
}


- (void)kickOffMotionAndBluetooth:(int)surveyLengthSeconds {
    NSLog(@"kicking off CMMotionManager");
    self.motionManager = [[CMMotionManager alloc] init];
    // motionManager.startMagnetometerUpdates(to: OperationQueue.main, withHandler: updateMotionManagerHandler!)
    [self.motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
        if (error) {
            NSLog(@"startMagnetometerUpdatesToQueue error: %@", error);
        } else {
            self.lastMagnetometerData = magnetometerData;
        }
    }];

    NSLog(@"kicking off CBCentralManager");
    // print time
    NSLog(@"time: %f", [[NSDate date] timeIntervalSince1970]);

    // kick off the survey by init'ing the corebluetooth manager
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [NSTimer scheduledTimerWithTimeInterval:surveyLengthSeconds target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];    
}

+ (instancetype)sharedInstance {
    NSLog(@"sharedInstance");
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
        // print mutex
        NSLog(@"sharedInstance mutex: %d", [sharedInstance isScanning]);
    });
    return sharedInstance;
}

- (void)startScanning {
    NSLog(@"startScanning called --- calling scanForPeripheralsWithServices");
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (void)stopScanning {
    NSLog(@"stopScanning called");
    NSLog(@"time: %f", [[NSDate date] timeIntervalSince1970]);

    [self.centralManager stopScan];

    // do a track once call to force the OS to give us a fresh location, and include that as part of the payload (include it in every line)
    // also create a unique scanid value that will be added to every line

    // join all self.bluetoothReadings with newlines and POST to server
    NSString *payload = [self.bluetoothReadings componentsJoinedByString:@"\n"];

    NSLog(@"self.isWhereAmIScan %d", self.isWhereAmIScan);

    // if self.isWhereAmIScan, call callback with the payload string
    if (self.isWhereAmIScan) {
        if (self.completionHandler) {
            self.completionHandler(payload);
        }
    } else {
        // this is a survey scan i.e. we are sending data back to the
        // ML server for training purposes

        // POST payload
        // TODO move to prod server..?
        NSURL *url = [NSURL URLWithString:@"https://ml-hetzner.radarindoors.com/scan_results"];
        NSLog(@"url: %@", url);

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
        [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (data && self.completionHandler) {
                // decode data to string
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"responseString: %@", responseString);
                self.completionHandler(responseString);
            }
        }];
        [task resume];
    }

    NSLog(@"callign removeAllObjects, clearing scanId, etc.");

    // removeAllObjects from bluetooth readings i.e. clear array
    [self.bluetoothReadings removeAllObjects];
    // reset self.scanId
    self.scanId = nil;
    // reset self.locationAtTimeOfSurveyStart
    self.locationAtTimeOfSurveyStart = nil;
    // reset self.lastMagnetometerData
    self.lastMagnetometerData = nil;

    // set mutex to off
    self.isScanningMutex = NO;

    NSLog(@"stopScanning end");
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOff:
            NSLog(@"CBCentralManager: Is Powered Off.");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@"CBCentralManager: Is Powered On.");
            // print time
            NSLog(@"time: %f", [[NSDate date] timeIntervalSince1970]);
            [self startScanning];
            break;
        case CBManagerStateUnsupported:
            NSLog(@"CBCentralManager: Is Unsupported.");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"CBCentralManager: Is Unauthorized.");
            break;
        case CBManagerStateUnknown:
            NSLog(@"CBCentralManager: Unknown");
            break;
        case CBManagerStateResetting:
            NSLog(@"CBCentralManager: Resetting");
            break;
        default:
            NSLog(@"CBCentralManager: Error");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *manufacturerId = @"";
    NSData *manufacturerData = advertisementData[@"kCBAdvDataManufacturerData"];
    if (manufacturerData) {
        manufacturerId = [NSString stringWithFormat:@"%04X", (UInt16)(((uint8_t *)manufacturerData.bytes)[0] + ((uint8_t *)manufacturerData.bytes)[1] << 8)];
    }

    NSString *name = peripheral.name ?: @"(no name)";

    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];

    // extract kCBAdvDataServiceUUIDs from advertisement data if it's available
    NSArray<CBUUID *> *serviceUUIDs = advertisementData[@"kCBAdvDataServiceUUIDs"];
    // join service uuids into string or store "(no services)" if array is empty/nil
    NSString *serviceUUIDsString = serviceUUIDs ? [serviceUUIDs componentsJoinedByString:@","] : @"(no services)";

    NSURLComponents *components = [NSURLComponents componentsWithString: @""];
    NSArray<NSURLQueryItem *> *queryItems = @[
        [NSURLQueryItem queryItemWithName:@"time" value:[NSString stringWithFormat:@"%f", timestamp]],
        [NSURLQueryItem queryItemWithName:@"label" value:self.placeLabel],
        [NSURLQueryItem queryItemWithName:@"peripheral.identifier" value:[peripheral.identifier UUIDString]],
        [NSURLQueryItem queryItemWithName:@"peripheral.name" value:name],
        [NSURLQueryItem queryItemWithName:@"rssi" value:[RSSI stringValue]],
        [NSURLQueryItem queryItemWithName:@"manufacturerId" value:manufacturerId],
        [NSURLQueryItem queryItemWithName:@"scanId" value:self.scanId],
        [NSURLQueryItem queryItemWithName:@"serviceUUIDs" value:serviceUUIDsString],

        [NSURLQueryItem queryItemWithName:@"location.coordinate.latitude" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.coordinate.latitude]],
        [NSURLQueryItem queryItemWithName:@"location.coordinate.longitude" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.coordinate.longitude]],
        [NSURLQueryItem queryItemWithName:@"location.horizontalAccuracy" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.horizontalAccuracy]],
        [NSURLQueryItem queryItemWithName:@"location.verticalAccuracy" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.verticalAccuracy]],
        [NSURLQueryItem queryItemWithName:@"location.altitude" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.altitude]],
        [NSURLQueryItem queryItemWithName:@"location.ellipsoidalAltitude" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.ellipsoidalAltitude]],
        [NSURLQueryItem queryItemWithName:@"location.timestamp" value:[NSString stringWithFormat:@"%f", self.locationAtTimeOfSurveyStart.timestamp]],
        [NSURLQueryItem queryItemWithName:@"location.floor" value:[NSString stringWithFormat:@"%d", self.locationAtTimeOfSurveyStart.floor]],

        [NSURLQueryItem queryItemWithName:@"sdkVersion" value:[RadarUtils sdkVersion]],
        [NSURLQueryItem queryItemWithName:@"deviceType" value:[RadarUtils deviceType]],
        [NSURLQueryItem queryItemWithName:@"deviceMake" value:[RadarUtils deviceMake]],
        [NSURLQueryItem queryItemWithName:@"deviceModel" value:[RadarUtils deviceModel]],
        [NSURLQueryItem queryItemWithName:@"deviceOS" value:[RadarUtils deviceOS]],

        // inject x, y, z from self.lastMagnetometerData
        // and add sqrt(pow(magnet.field.x, 2) + pow(magnet.field.y, 2) + pow(magnet.field.z, 2)) as well
        [NSURLQueryItem queryItemWithName:@"magnetometer.field.x" value:[NSString stringWithFormat:@"%f", self.lastMagnetometerData.magneticField.x]],
        [NSURLQueryItem queryItemWithName:@"magnetometer.field.y" value:[NSString stringWithFormat:@"%f", self.lastMagnetometerData.magneticField.y]],
        [NSURLQueryItem queryItemWithName:@"magnetometer.field.z" value:[NSString stringWithFormat:@"%f", self.lastMagnetometerData.magneticField.z]],
        [NSURLQueryItem queryItemWithName:@"magnetometer.timestamp" value:[NSString stringWithFormat:@"%f", self.lastMagnetometerData.timestamp]],
        [NSURLQueryItem queryItemWithName:@"magnetometer.field.magnitude" value:[NSString stringWithFormat:@"%f", sqrt(pow(self.lastMagnetometerData.magneticField.x, 2) + pow(self.lastMagnetometerData.magneticField.y, 2) + pow(self.lastMagnetometerData.magneticField.z, 2))]],

    ];
    components.queryItems = queryItems;
    NSURL *dataUrl = components.URL;
    // stringify dataurl
    NSString *queryString = [dataUrl absoluteString];
    [self.bluetoothReadings addObject:queryString];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"centralManager didConnectPeripheral, calling stopScanning");
    [self stopScanning];
}

@end
