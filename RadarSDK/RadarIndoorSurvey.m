#import "RadarIndoorSurvey.h"
#import "NSData+GZIP.h"
#import "RadarUtils.h"
#import "RadarLogger.h"
#import "RadarLocationManager.h"

@implementation RadarIndoorSurvey

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isScanning = NO;
    }
    return self;
}

- (void)start:(NSString *)placeLabel forLength:(int)surveyLengthSeconds withKnownLocation:(CLLocation *)knownLocation isWhereAmIScan:(BOOL)isWhereAmIScan withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler {
    // convert to [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message]; call
    // NSLog(@"start called with placeLabel: %@, surveyLengthSeconds: %d, isWhereAmIScan: %d", placeLabel, surveyLengthSeconds, isWhereAmIScan);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"start called with placeLabel: %@, surveyLengthSeconds: %d, isWhereAmIScan: %d", placeLabel, surveyLengthSeconds, isWhereAmIScan]];

    // log self.isScanning
    // NSLog(@"self.isScanning: %d", self.isScanning);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"self.isScanning: %d", self.isScanning]];

    if(self.isScanning) {
        // NSLog(@"Error: start called while already scanning");
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"Error: start called while already scanning"];

        // call callback, pass bad data
        completionHandler(@"Error: start called while already scanning");

        return;
    }

    // set self.isScanning to YES
    self.isScanning = YES;

    self.placeLabel = placeLabel;
    self.completionHandler = completionHandler;
    self.bluetoothReadings = [NSMutableArray new];

    self.isWhereAmIScan = isWhereAmIScan;

    // set fresh uuid on self.scanId
    self.scanId = [[NSUUID UUID] UUIDString];

    // if isWhereAmIScan but no knownLocation, throw error
    // as we are expecting to have been called from track
    if (isWhereAmIScan && !knownLocation) {
        // convert to [[RadarLogger sharedInstance]
        // NSLog(@"Error: start called with isWhereAmIScan but no knownLocation");
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"Error: start called with isWhereAmIScan but no knownLocation"];
        completionHandler(@"Error: start called with isWhereAmIScan but no knownLocation");
        self.isScanning = NO;
        return;
    } else if(isWhereAmIScan && knownLocation) {
        // if isWhereAmIScan and knownLocation,
        // set self.locationAtTimeOfSurveyStart to knownLocation
        self.locationAtTimeOfSurveyStart = knownLocation;

        [self kickOffMotionAndBluetooth:surveyLengthSeconds];
    } else if(!isWhereAmIScan) {        
        // get location at time of survey start

        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo type:RadarLogTypeSDKCall message:@"calling RadarLocationManager getLocationWithDesiredAccuracy"];
        [[RadarLocationManager sharedInstance]
            getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium
                         completionHandler:^(RadarStatus status, CLLocation *_Nullable location, BOOL stopped) {
                             if (status != RadarStatusSuccess) {
                                 return;
                             }

                             // NSLog(@"location: %f, %f", location.coordinate.latitude, location.coordinate.longitude);
                             [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"location: %f, %f", location.coordinate.latitude, location.coordinate.longitude]];
                             // print location object as is
                             // NSLog(@"%@", location);
                             [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"%@", location]];

                             // set self.locationAtTimeOfSurveyStart to location
                             self.locationAtTimeOfSurveyStart = location;

                             [self kickOffMotionAndBluetooth:surveyLengthSeconds];
        }];
    }
}

- (void)kickOffMotionAndBluetooth:(int)surveyLengthSeconds {
    // NSLog(@"kicking off CMMotionManager");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"kicking off CMMotionManager"];
    self.motionManager = [[CMMotionManager alloc] init];
    // motionManager.startMagnetometerUpdates(to: OperationQueue.main, withHandler: updateMotionManagerHandler!)
    [self.motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
        if (error) {
            // NSLog(@"startMagnetometerUpdatesToQueue error: %@", error);
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:[NSString stringWithFormat:@"startMagnetometerUpdatesToQueue error: %@", error]];
        } else {
            self.lastMagnetometerData = magnetometerData;
        }
    }];

    // NSLog(@"kicking off CBCentralManager");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"kicking off CBCentralManager"];
    // print time
    // NSLog(@"time: %f", [[NSDate date] timeIntervalSince1970]);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"time: %f", [[NSDate date] timeIntervalSince1970]]];

    // kick off the survey by init'ing the corebluetooth manager
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [NSTimer scheduledTimerWithTimeInterval:surveyLengthSeconds target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];    
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (void)startScanning {
    // NSLog(@"startScanning called --- calling scanForPeripheralsWithServices");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"startScanning called --- calling scanForPeripheralsWithServices"];
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (void)stopScanning {
    // NSLog(@"stopScanning called");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"stopScanning called"];
    // NSLog(@"time: %f", [[NSDate date] timeIntervalSince1970]);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"time: %f", [[NSDate date] timeIntervalSince1970]]];

    [self.centralManager stopScan];

    // do a track once call to force the OS to give us a fresh location, and include that as part of the payload (include it in every line)
    // also create a unique scanid value that will be added to every line

    // join all self.bluetoothReadings with newlines and POST to server
    NSString *payload = [self.bluetoothReadings componentsJoinedByString:@"\n"];

    // if [RadarUtils isSimulator] , put fake data into payload

    // NSLog(@"[RadarUtils isSimulator]: %d", [RadarUtils isSimulator]);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"[RadarUtils isSimulator]: %d", [RadarUtils isSimulator]]];

    if ([RadarUtils isSimulator]) {
        payload = @"?time=1716583686.556668&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=C9AC95A0-D6B5-D57F-014B-0FDD11D51E7E&peripheral.name=(no%20name)&rssi=-88&manufacturerId=&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.559950&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=540803B9-86A3-CF2E-2A4B-1B23C6DB0214&peripheral.name=%5BTV%5D%20Samsung%209%20Series%20(86)&rssi=-71&manufacturerId=7500&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.560602&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=540803B9-86A3-CF2E-2A4B-1B23C6DB0214&peripheral.name=%5BTV%5D%20Samsung%209%20Series%20(86)&rssi=-71&manufacturerId=7500&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.563503&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=E25D13C2-08A0-9598-327A-CC4B2F782E53&peripheral.name=(no%20name)&rssi=-70&manufacturerId=&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.568083&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=0B9BD1B0-D482-31D2-B723-882E5AD9FCEA&peripheral.name=(no%20name)&rssi=-88&manufacturerId=0600&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.572948&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=D48D165B-FE69-C705-6B14-4000822C5EC7&peripheral.name=(no%20name)&rssi=-78&manufacturerId=&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.573204&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=D48D165B-FE69-C705-6B14-4000822C5EC7&peripheral.name=(no%20name)&rssi=-78&manufacturerId=&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.573577&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=E6FD4D8E-6C80-EACC-6B93-9DDB8D9AAAA5&peripheral.name=(no%20name)&rssi=-73&manufacturerId=&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-35.025116&magnetometer.field.y=-112.979324&magnetometer.field.z=-240.243347&magnetometer.timestamp=65614.479717&magnetometer.field.magnitude=267.783406\n?time=1716583686.590971&label=FAKE-SIMULATOR-FAKE-SIMULATOR-geofence.description:RDR-T__geofence._id:664dfae54dfd1b59d5aff925&peripheral.identifier=571CE11A-F8BE-43AC-460C-C1A9FA3F0406&peripheral.name=(no%20name)&rssi=-64&manufacturerId=&scanId=4FCAE527-99B8-4BB8-81F3-75D41C2323B1&serviceUUIDs=(no%20services)&location.coordinate.latitude=40.734173&location.coordinate.longitude=-73.990878&location.horizontalAccuracy=21.840953&location.verticalAccuracy=24.163757&location.altitude=41.885521&location.ellipsoidalAltitude=8.913273&location.timestamp=-0.000000&location.floor=0&sdkVersion=3.9.12&deviceType=iOS&deviceMake=Apple&deviceModel=iPhone14,2&deviceOS=17.4.1&magnetometer.field.x=-29.425323&magnetometer.field.y=-112.600601&magnetometer.field.z=-246.101929&magnetometer.timestamp=65614.520519&magnetometer.field.magnitude=272.233180\n";
    }

    // print length of payload
    // NSLog(@"payload length: %lu", (unsigned long)[payload length]);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"payload length: %lu", (unsigned long)[payload length]]];

    // compress payload and base64 encode it

    // compress payload
    NSData *compressedData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressedDataGzipped = [compressedData gzippedData];
    // print length of compressed payload
    // NSLog(@"compressedDataGzipped length: %lu", (unsigned long)[compressedDataGzipped length]);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"compressedDataGzipped length: %lu", (unsigned long)[compressedDataGzipped length]]];

    // base64 encode
    NSString *compressedDataGzippedBase64 = [compressedDataGzipped base64EncodedStringWithOptions:0];
     
    // print length of base64 encoded payload
    // NSLog(@"compressedDataGzippedBase64 length: %lu", (unsigned long)[compressedDataGzippedBase64 length]);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"compressedDataGzippedBase64 length: %lu", (unsigned long)[compressedDataGzippedBase64 length]]];

    // NSLog(@"self.isWhereAmIScan %d", self.isWhereAmIScan);
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"self.isWhereAmIScan %d", self.isWhereAmIScan]];

    // if self.isWhereAmIScan, call callback with the payload string
    if (self.isWhereAmIScan) {
        if (self.completionHandler) {
            self.completionHandler(compressedDataGzippedBase64);
        }
    } else {
        // this is a survey scan i.e. we are sending data back to the
        // ML server for training purposes

        // POST payload
        // TODO move to prod server..?
        NSURL *url = [NSURL URLWithString:@"https://ml-hetzner.radarindoors.com/scan_results"];

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:[compressedDataGzippedBase64 dataUsingEncoding:NSUTF8StringEncoding]];
        [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (data && self.completionHandler) {
                // decode data to string
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // NSLog(@"responseString: %@", responseString);
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"responseString: %@", responseString]];
                self.completionHandler(responseString);
            }
        }];
        [task resume];
    }

    // NSLog(@"callign removeAllObjects, clearing scanId, etc.");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"callign removeAllObjects, clearing scanId, etc."];

    // removeAllObjects from bluetooth readings i.e. clear array
    [self.bluetoothReadings removeAllObjects];
    // reset self.scanId
    self.scanId = nil;
    // reset self.locationAtTimeOfSurveyStart
    self.locationAtTimeOfSurveyStart = nil;
    // reset self.lastMagnetometerData
    self.lastMagnetometerData = nil;

    // NSLog(@"stopScanning end");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"stopScanning end"];

    // set self.isScanning to NO
    self.isScanning = NO;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOff:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Is Powered Off."];
            break;
        case CBManagerStatePoweredOn:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Is Powered On."];
            // print time
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"time: %f", [[NSDate date] timeIntervalSince1970]]];
            [self startScanning];
            break;
        case CBManagerStateUnsupported:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Is Unsupported."];
            break;
        case CBManagerStateUnauthorized:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Is Unauthorized."];
            break;
        case CBManagerStateUnknown:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Unknown"];
            break;
        case CBManagerStateResetting:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Resetting"];
            break;
        default:
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"CBCentralManager: Error"];
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

    // extract kCBAdvDataIsConnectable from advertisement data if it's available
    NSNumber *isConnectable = advertisementData[@"kCBAdvDataIsConnectable"];

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

        // inject isConnectable
        [NSURLQueryItem queryItemWithName:@"isConnectable" value:[isConnectable stringValue]]
    ];
    components.queryItems = queryItems;
    NSURL *dataUrl = components.URL;
    // stringify dataurl
    NSString *queryString = [dataUrl absoluteString];
    [self.bluetoothReadings addObject:queryString];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // NSLog(@"centralManager didConnectPeripheral, calling stopScanning");
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"centralManager didConnectPeripheral, calling stopScanning"];
    [self stopScanning];
}

@end