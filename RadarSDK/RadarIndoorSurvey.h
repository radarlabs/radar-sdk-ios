#import <CoreBluetooth/CoreBluetooth.h>

#import "Radar.h"
#import "RadarUtils.h"

@interface RadarIndoorSurvey : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, strong) NSString *placeLabel;
@property (nonatomic, copy) RadarIndoorsSurveyCompletionHandler completionHandler;
@property (nonatomic, strong) NSMutableArray *bluetoothReadings;
// add a scanid uuid property to the class
@property (nonatomic, strong) NSString *scanId;
// add a locationAtTimeOfSurveyStart CLLocation property to the class
@property (nonatomic, strong) CLLocation *locationAtTimeOfSurveyStart;

// store whether this is a whereAmI scan
@property (nonatomic) BOOL isWhereAmIScan;
// store whether we are scannig
@property (nonatomic) BOOL isScanning;

#define WHERE_AM_I_DURATION_SECONDS 10

+ (instancetype)sharedInstance;

- (void)start:(NSString *)placeLabel forLength:(int)surveyLengthSeconds withKnownLocation:(CLLocation *)knownLocation isWhereAmIScan:(BOOL)isWhereAmIScan withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;
- (void)startScanning;
- (void)stopScanning;
- (void)kickOffMotionAndBluetooth:(int)surveyLengthSeconds;

@end
