#import "RadarIndoorSurvey.h"

// FIXME use reasonable period of time i.e. 5 mins
#define INDOORS_SURVEY_LENGTH_SECONDS 5

@implementation RadarIndoorSurvey

- (void)start:(NSString *)placeLabel withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler {
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.placeLabel = placeLabel;
    self.completionHandler = completionHandler;

    self.bluetoothReadings = [NSMutableArray new];

    [NSTimer scheduledTimerWithTimeInterval:INDOORS_SURVEY_LENGTH_SECONDS target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];
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
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (void)stopScanning {
    [self.centralManager stopScan];

    // join all self.bluetoothReadings with newlines and POST to server
    NSString *payload = [self.bluetoothReadings componentsJoinedByString:@"\n"];

    // server url path is https://af4c965eedb5.ngrok.app/scan_results
    // POST payload to URL above

    // FIXME don't use ngrok
    NSURL *url = [NSURL URLWithString:@"https://af4c965eedb5.ngrok.app/scan_results"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            // Do something with data
        }
    }];
    [task resume];

    if (self.completionHandler) {
        self.completionHandler();
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOff:
            NSLog(@"CBCentralManager: Is Powered Off.");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@"CBCentralManager: Is Powered On.");
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

    // FIXME url encode (or json, etc.) string -- right now, a "&" in a place label
    // or bluetooth device name would wreck havoc on parsing.
    NSString *queryString = [NSString stringWithFormat:@"time=%f&label=%@&peripheral.identifier=%@&rssi=%@&manufacturerId=%@&peripheral.name=%@", timestamp, self.placeLabel, peripheral.identifier, RSSI, manufacturerId, name];
    
    [self.bluetoothReadings addObject:queryString];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self stopScanning];
}

@end
