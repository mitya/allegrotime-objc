//
//  Created by Dima on 25.03.12.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Helpers.h"

/******************************************************************************/

typedef enum {
  ClosingDirectionToFinland = 1,
  ClosingDirectionToRussia = 2
} ClosingDirection;

typedef enum CrossingState {
  CrossingStateClear,
  CrossingStateSoon,
  CrossingStateVerySoon,
  CrossingStateClosing,
  CrossingStateClosed,
  CrosingsStateJustOpened
} CrossingState;

typedef enum {
  StateColorGreen,
  StateColorYellow,
  StateColorRed
} StateColor;

@class Crossing;

#define PREVIOUS_TRAIN_LAG_TIME 10

/******************************************************************************/

@interface Closing : NSObject

@property (nonatomic, strong) NSString *time;
@property (nonatomic, assign) Crossing *crossing;
@property (nonatomic) ClosingDirection direction;
@property (nonatomic) int timeInMinutes;
@property (nonatomic, readonly) int stopTimeInMinutes;
@property (nonatomic, readonly) BOOL toRussia;
@property (nonatomic, readonly) int trainNumber;
@property (nonatomic, readonly) BOOL isClosest;
@property (nonatomic, readonly) CrossingState state;
@property (nonatomic, readonly) UIColor *color;

+ (id)closingWithCrossingName:(NSString *)crossingName time:(NSString *)time direction:(ClosingDirection)direction;

@end

/******************************************************************************/

@interface Crossing : NSObject <MKAnnotation>

@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *closings;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) Closing *nextClosing;
@property (nonatomic, readonly) Closing *previousClosing;
@property (nonatomic, readonly) CrossingState state;
@property (nonatomic, readonly) UIColor *color;
@property (nonatomic, readonly) int minutesTillNextClosing;
@property (nonatomic, readonly) BOOL isClosest;
@property (nonatomic, assign) int distance;
@property (nonatomic, readonly) NSInteger index;
+ (Crossing *)crossingWithName:(NSString *)name latitude:(double)lat longitude:(double)lng;
+ (Crossing *)getCrossingWithName:(NSString *)name;

- (void)addClosingWithTime:(NSString *)time direction:(ClosingDirection)direction;
@end

/******************************************************************************/

@interface ModelManager : NSObject

@property (nonatomic, strong) NSMutableArray *crossings;
@property (nonatomic, strong) NSMutableArray *closings;
@property (nonatomic, strong) Crossing *closestCrossing;
@property (nonatomic, strong) Crossing *selectedCrossing;
@property (nonatomic, strong) Crossing *currentCrossing;
@property (nonatomic, readonly, strong) Crossing *defaultCrossing;

- (Crossing *)crossingClosestTo:(CLLocation *)location;

+ (void)prepare;

@end

ModelManager *model;
