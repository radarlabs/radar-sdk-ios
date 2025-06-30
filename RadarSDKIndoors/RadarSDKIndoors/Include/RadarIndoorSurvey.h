#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

// Forward declare the completion handler type
typedef void (^_Nonnull RadarIndoorsSurveyCompletionHandler)(NSString *_Nullable result, CLLocation *_Nullable locationAtStartOfSurvey);

@class Radar;

NS_ASSUME_NONNULL_BEGIN

@interface RadarIndoorSurvey : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nullable, nonatomic, strong) NSString *placeLabel;
@property (nonatomic, copy) RadarIndoorsSurveyCompletionHandler completionHandler;
@property (nonatomic, strong) NSMutableArray *bluetoothReadings;
@property (nullable, nonatomic, strong) NSString *scanId;
@property (nullable, nonatomic, strong) CLLocation *locationAtTimeOfSurveyStart;
@property (nullable, nonatomic, strong) CMMagnetometerData *lastMagnetometerData;
@property (nonatomic) BOOL isWhereAmIScan;
@property (nonatomic) BOOL isScanning;

#define WHERE_AM_I_DURATION_SECONDS 10

+ (instancetype)sharedInstance;

- (void)start:(NSString *)placeLabel forLength:(int)surveyLengthSeconds withKnownLocation:(CLLocation *_Nullable)knownLocation isWhereAmIScan:(BOOL)isWhereAmIScan withCompletionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;
- (void)startScanning;
- (void)stopScanning;
- (void)kickOffMotionAndBluetooth:(int)surveyLengthSeconds;

@end

NS_ASSUME_NONNULL_END
