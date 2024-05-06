#import <CoreBluetooth/CoreBluetooth.h>

#import "Radar.h"

@interface RadarIndoorSurvey : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSString *placeLabel;
@property (nonatomic, copy) RadarIndoorsSurveyCompletionHandler completionHandler;
@property (nonatomic, strong) NSMutableArray *bluetoothReadings;

+ (instancetype)sharedInstance;

- (void)start:(NSString *)placeLabel withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;
- (void)startScanning;
- (void)stopScanning;

@end
