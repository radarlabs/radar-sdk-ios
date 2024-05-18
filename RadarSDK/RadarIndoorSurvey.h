#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>

#import "Radar.h"
#import "RadarUtils.h"

@interface RadarIndoorSurvey : NSObject <CBCentralManagerDelegate>

// mutex -- am i already scanning?
@property (nonatomic) BOOL isScanningMutex;
@property (nonatomic, strong) CBCentralManager *centralManager;
// also store a CMMotionManager property
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSString *placeLabel;
@property (nonatomic, copy) RadarIndoorsSurveyCompletionHandler completionHandler;
@property (nonatomic, strong) NSMutableArray *bluetoothReadings;
// add a scanid uuid property to the class
@property (nonatomic, strong) NSUUID *scanId;
// add a locationAtTimeOfSurveyStart CLLocation property to the class
@property (nonatomic, strong) CLLocation *locationAtTimeOfSurveyStart;
// store last received magnet data
@property (nonatomic, strong) CMMagnetometerData *lastMagnetometerData;
// store whether this is a whereAmI scan
@property (nonatomic) BOOL isWhereAmIScan;

#define WHERE_AM_I_DURATION_SECONDS 20

+ (instancetype)sharedInstance;

- (void)start:(NSString *)placeLabel forLength:(int)surveyLengthSeconds withKnownLocation:(CLLocation *)knownLocation isWhereAmIScan:(BOOL)isWhereAmIScan withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;
- (void)startScanning;
- (void)stopScanning;
- (void)kickOffMotionAndBluetooth:(int)surveyLengthSeconds;
- (BOOL)isScanning;

@end
