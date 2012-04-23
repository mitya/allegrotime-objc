//
//  Created by Dima on 26.03.12.
//


#import "Helpers.h"

void gLogArray(char const *desc, NSArray *array) {
  NSLog(@"%s array dump:", desc);
  for (int i = 0; i < array.count; i++) {
    NSLog(@"  %2i: %@", i, [array objectAtIndex:i]);
  }
}

void gLogString(char const *string) {
  NSLog(@"%s", string);
}

void gLogSelector(SEL selector) {
  NSLog(@">> %s", (char *) selector);
}

void gLog(char const *desc, id object) {
  if ([object isKindOfClass:NSArray.class]) {
    gLogArray(desc, object);
  } else {
    NSLog(@"%s = %@", desc, object);
  }
}

void gDump(id object) {
  NSLog(@"%@", object);
}

/******************************************************************************/

@implementation NSString (My)
- (NSString *)format:(id)objects, ... {
  return [NSString stringWithFormat:self, objects];
}

- (NSString *)transliterated {
  NSMutableString *buffer = [self mutableCopy];
  CFMutableStringRef bufferRef = (__bridge CFMutableStringRef) buffer;
  CFStringTransform(bufferRef, NULL, kCFStringTransformToLatin, false);
  CFStringTransform(bufferRef, NULL, kCFStringTransformStripCombiningMarks, false);
  CFStringTransform(bufferRef, NULL, kCFStringTransformStripDiacritics, false);
  [buffer replaceOccurrencesOfString:@"ʹ" withString:@"" options:0 range:NSMakeRange(0, buffer.length)];
  [buffer replaceOccurrencesOfString:@"–" withString:@"-" options:0 range:NSMakeRange(0, buffer.length)];
  return buffer;
}

@end

/******************************************************************************/

@implementation NSArray (My)

- (id)firstObject {
  if (self.count == 0)
    return nil;
  return [self objectAtIndex:0];
}

- (id)minimumObject:(double (^)(id object))valueSelector {
  double minValue = valueSelector([self firstObject]);
  id minObject = [self firstObject];

  for (id object in self) {
    double value = valueSelector(object);
    if (value < minValue) {
      minValue = value;
      minObject = object;
    }
  }

  return minObject;
}

- (id)detectObject:(BOOL (^)(id object))predicate {
  for (id object in self) {
    if (predicate(object))
      return object;
  }
  return nil;
}

@end

/******************************************************************************/

@implementation Helper

+ (NSInteger)parseStringAsHHMM:(NSString *)string {
  NSArray *components = [string componentsSeparatedByString:@":"];
  NSInteger hours = [[components objectAtIndex:0] integerValue];
  NSInteger minutes = [[components objectAtIndex:1] integerValue];
  return hours * 60 + minutes;
}

+ (NSInteger)currentTimeInMinutes {
  NSDate *now = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *nowParts = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:now];

  NSInteger hours = nowParts.hour;
  NSInteger minutes = nowParts.minute;
  return hours * 60 + minutes;
}

+ (NSString *)formatDate:(NSDate *)date withFormat:(NSString *)format {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:format];
  return [dateFormatter stringFromDate:date];
}

+ (NSComparisonResult)compareInteger:(int)num1 with:(int)num2 {
  if (num1 < num2)
    return -1;
  else if (num1 > num2)
    return 1;
  else
    return 0;

}

+ (UILabel *)labelForTableViewFooter {
  UILabel *label = [[UILabel alloc] init];
  label.backgroundColor = [UIColor clearColor];
  label.font = [UIFont systemFontOfSize:15];
  label.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1];
  label.shadowColor = [UIColor colorWithWhite:1 alpha:1];
  label.shadowOffset = CGSizeMake(0, 1);
  label.textAlignment = UITextAlignmentCenter;
  return label;
}

+ (float)tableViewCellWidth {
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 680 : 300;
}

+ (UIActivityIndicatorView *)spinnerAfterCenteredLabel:(UILabel *)label {
  CGSize labelSize = [label.text sizeWithFont:label.font];
  UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  spinner.center = CGPointMake(labelSize.width + (label.frame.size.width - labelSize.width) / 2 + spinner.frame.size.width, label.center.y);
  return spinner;
}

+ (NSString *)formatTimeInMunutesAsHHMM:(int)minutesSinceMidnight {
  int hours = minutesSinceMidnight / 60;
  int minutes = minutesSinceMidnight - hours * 60;
  return [NSString stringWithFormat:@"%02i:%02i", hours, minutes];
}

+ (UIColor *)greenColor {
  return [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
}

+ (UIColor *)yellowColor {
  return [UIColor colorWithRed:1 green:0.6 blue:0 alpha:1];
}

+ (int)roundToFive:(int)value {
  int remainder = value - value / 5 * 5;
  int remainderInverse = 5 - remainder;
  return remainder <= 2 ? value - remainder : value + remainderInverse;
}

+ (NSTimeInterval)timeTillFullMinute {
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSSecondCalendarUnit fromDate:[NSDate date]];
  return 60 - dateComponents.second;
}

+ (NSDate *)nextFullMinuteDate {
  return [NSDate dateWithTimeIntervalSinceNow:[self timeTillFullMinute]];
}

+ (UIColor *)cellGradientColorFor:(UIColor *)color {
  if (color == [UIColor redColor])
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-RedGradient.png"]];
  if (color == [UIColor yellowColor])
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-YellowGradient.png"]];
  if (color == [UIColor greenColor])
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-GreenGradient.png"]];
  return color;
}

+ (UIColor *)blueTextColor {
  return [UIColor colorWithRed:82.0/255 green:102.0/255 blue:145.0/255 alpha:1];
}

@end
