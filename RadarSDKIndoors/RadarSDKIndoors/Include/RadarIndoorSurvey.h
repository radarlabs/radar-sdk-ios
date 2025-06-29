#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

// Forward declare the completion handler type
typedef void (^_Nonnull RadarIndoorsSurveyCompletionHandler)(NSString *_Nullable result, CLLocation *_Nonnull locationAtStartOfSurvey);

@class Radar;

@interface RadarIndoorSurvey : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSString *placeLabel;
@property (nonatomic, copy) RadarIndoorsSurveyCompletionHandler completionHandler;
@property (nonatomic, strong) NSMutableArray *bluetoothReadings;
@property (nonatomic, strong) NSString *scanId;
@property (nonatomic, strong) CLLocation *locationAtTimeOfSurveyStart;
@property (nonatomic, strong) CMMagnetometerData *lastMagnetometerData;
@property (nonatomic) BOOL isWhereAmIScan;
@property (nonatomic) BOOL isScanning;

#define WHERE_AM_I_DURATION_SECONDS 10

+ (instancetype)sharedInstance;

- (void)start:(NSString *)placeLabel forLength:(int)surveyLengthSeconds withKnownLocation:(CLLocation *)knownLocation isWhereAmIScan:(BOOL)isWhereAmIScan withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;
- (void)startScanning;
- (void)stopScanning;
- (void)kickOffMotionAndBluetooth:(int)surveyLengthSeconds;

@end
