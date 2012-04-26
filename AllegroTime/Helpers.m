//
//  Created by Dima on 26.03.12.
//


#import "Helpers.h"

NSString *const NXClosestCrossingChanged = @"NXClosestCrossingChangedNotification";
NSString *const NXLogConsoleUpdated = @"NXLogConsoleUpdated";
NSString *const NXLogConsoleFlushed = @"NXLogConsoleFlushed";
NSString *const NXModelUpdated = @"NXUpdateDataStatus";
NSString *const MXDefaultCellID = @"MXDefaultCellID";

#pragma mark - Logging

void MXLogArray(char const *desc, NSArray *array) {
  NSLog(@"%s array dump:", desc);
  for (int i = 0; i < array.count; i++) {
    NSLog(@"  %2i: %@", i, [array objectAtIndex:i]);
  }
}

void MXLogString(char const *string) {
  NSLog(@"%s", string);
}

void MXLogSelector(SEL selector) {
  NSLog(@">> %s", (char *) selector);
}

void MXLog(char const *desc, id object) {
  if ([object isKindOfClass:NSArray.class]) {
    MXLogArray(desc, object);
  } else {
    NSLog(@"%s = %@", desc, object);
  }
}

void MXDump(id object) {
  NSLog(@"%@", object);
}

NSMutableArray *MXLoggingBuffer;

NSMutableArray *MXGetConsole() {
  if (!MXLoggingBuffer) {
    MXLoggingBuffer = [NSMutableArray arrayWithCapacity:1000];
  }
  return MXLoggingBuffer;
}

void MXWriteToConsole(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *formattedMessage = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  NSLog(@"%@", formattedMessage);

  formattedMessage = [NSString stringWithFormat:@"%@ %@\n", MXFormatDate([NSDate date], @"HH:mm:ss"), formattedMessage];
  [MXGetConsole() addObject:formattedMessage];

  [NSNotificationCenter.defaultCenter postNotificationName:NXLogConsoleUpdated object:MXLoggingBuffer];

  if (MXLoggingBuffer.count > 200) {
    [MXLoggingBuffer removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 50)]];
    [NSNotificationCenter.defaultCenter postNotificationName:NXLogConsoleFlushed object:MXLoggingBuffer];
  }
}

#pragma mark - Formatters

// MXPluralizeRussiaWord(х, @"час", @"часа", @"часов")
// MXPluralizeRussiaWord(х, @"минута", @"минуты", @"минут")
NSString *MXPluralizeRussiaWord(int number, NSString *word1, NSString *word2, NSString *word5) {
  int rem100 = number % 100;
  int rem10 = number % 10;

  if (rem100 >= 11 && rem100 <= 19) return word5;
  if (rem10 == 0) return word5;
  if (rem10 == 1) return word1;
  if (rem10 >= 2 && rem10 <= 4) return word2;
  if (rem10 >= 5 && rem10 <= 9) return word5;

  return word5;
}

NSString *MXFormatMinutesAsText(int totalMinutes) {
  int hours = totalMinutes / 60;
  int minutes = totalMinutes % 60;
  NSString *hoursString = [NSString stringWithFormat:@"%i %@", hours, MXPluralizeRussiaWord(hours, @"час", @"часа", @"часов")];
  NSString *minutesString = [NSString stringWithFormat:@"%i %@", minutes, MXPluralizeRussiaWord(minutes, @"минута", @"минуты", @"минут")];
  if (hours == 0)
    return minutesString;
  else if (minutes == 0)
    return hoursString;
  else
    return [NSString stringWithFormat:@"%@ %@", hoursString, minutesString];
}

NSString *MXFormatDate(NSDate *date, NSString *format) {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:format];
  return [dateFormatter stringFromDate:date];
}

#pragma mark - UI

UIColor *MXCellGradientColorFor(UIColor *color) {
  static NSDictionary *mapping;
  if (!mapping)
    mapping = [NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-RedGradient.png"]], [UIColor redColor],
        [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-YellowGradient.png"]], [UIColor yellowColor],
        [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-GreenGradient.png"]], [UIColor greenColor],
        nil];

  return [mapping objectForKey:color];
}

BOOL MXAutorotationPolicy(UIInterfaceOrientation interfaceOrientation) {
  //if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  //  return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  //else
  return YES;
}

NSString *MXNameForColor(UIColor *color) {
  static NSDictionary *colorNames;
  if (!colorNames)
    colorNames = [NSDictionary dictionaryWithObjectsAndKeys:
        @"red", [UIColor redColor],
        @"yellow", [UIColor yellowColor],
        @"green", [UIColor greenColor],
        nil];
  return [colorNames objectForKey:color];
}

void MXSetGradientForCell(UITableViewCell *cell, UIColor *color) {
  static NSDictionary *textColorMapping;
  if (!textColorMapping)
    textColorMapping = [NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor whiteColor], [UIColor redColor],
        [UIColor darkGrayColor], [UIColor yellowColor],
        [UIColor whiteColor], [UIColor greenColor],
        nil];

  cell.backgroundColor = MXCellGradientColorFor(color);
  cell.textLabel.textColor = [textColorMapping objectForKey:color];
  cell.detailTextLabel.textColor = [textColorMapping objectForKey:color];
}

UILabel *MXConfigureLabelLikeInTableViewFooter(UILabel *label) {
  label.backgroundColor = [UIColor clearColor];
  label.font = [UIFont systemFontOfSize:15];
  label.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1];
  label.shadowColor = [UIColor colorWithWhite:1 alpha:1];
  label.shadowOffset = CGSizeMake(0, 1);
  label.textAlignment = UITextAlignmentCenter;
  return label;
}


#pragma mark - Core extensions

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

#pragma mark - Helpers module

@implementation Helper

+ (NSInteger)parseStringAsHHMM:(NSString *)string {
  NSArray *components = [string componentsSeparatedByString:@":"];
  NSInteger hours = [[components objectAtIndex:0] integerValue];
  NSInteger minutes = [[components objectAtIndex:1] integerValue];
  return hours * 60 + minutes;
}

+ (NSInteger)currentTimeInMinutes {
  static NSCalendar *calendar = nil;
  if (!calendar) calendar = [NSCalendar currentCalendar];

  NSDate *now = [NSDate date];
  NSDateComponents *nowParts = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:now];

  NSInteger hours = nowParts.hour;
  NSInteger minutes = nowParts.minute;
  return hours * 60 + minutes;
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

+ (UIColor *)blueTextColor {
  return [UIColor colorWithRed:82.0 / 255 green:102.0 / 255 blue:145.0 / 255 alpha:1];
}

@end

//void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight, BOOL top, BOOL bottom) {
//  float fw, fh;
//  if (ovalWidth == 0 || ovalHeight == 0) {
//    CGContextAddRect(context, rect);
//    return;
//  }
//  CGContextSaveGState(context);
//  CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
//  CGContextScaleCTM(context, ovalWidth, ovalHeight);
//  fw = CGRectGetWidth(rect) / ovalWidth;
//  fh = CGRectGetHeight(rect) / ovalHeight;
//  CGContextMoveToPoint(context, fw, fh / 2);
//  CGContextAddArcToPoint(context, fw, fh, fw / 2, fh, 0);
//
//  NSLog(@"bottom? %d", bottom);
//
//  if (top) {
//    CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, 3);
//  } else {
//    CGContextAddArcToPoint(context, 0, fh, 0, fh / 2, 0);
//  }
//
//  if (bottom) {
//    CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, 3);
//  } else {
//    CGContextAddArcToPoint(context, 0, 0, fw / 2, 0, 0);
//  }
//
//  CGContextAddArcToPoint(context, fw, 0, fw, fh / 2, 0);
//  CGContextClosePath(context);
//  CGContextRestoreGState(context);
//}
//
//UIImage *roundCornersOfImage(UIImage *source, BOOL roundTop, BOOL roundBottom) {
//  float w = source.size.width;
//  float h = source.size.height;
//
//  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//  CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
//
//  CGContextBeginPath(context);
//  CGRect rect = CGRectMake(0, 0, w, h);
//  addRoundedRectToPath(context, rect, 4, 4, top, bottom);
//  CGContextClosePath(context);
//  CGContextClip(context);
//
//  CGContextDrawImage(context, CGRectMake(0, 0, w, h), source.CGImage);
//
//  CGImageRef imageMasked = CGBitmapContextCreateImage(context);
//  CGContextRelease(context);
//  CGColorSpaceRelease(colorSpace);
//
//  return [UIImage imageWithCGImage:
//      imageMasked];
//}