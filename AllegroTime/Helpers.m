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

@implementation NSString (My)
- (NSString *)format:(id)objects, ... {
  return [NSString stringWithFormat:self, objects];
}
@end


@implementation NSArray (My)

- (id)firstObject {
  if (self.count == 0)
    return nil;
  return [self objectAtIndex:0];
}

- (id)minimumObject:(double (^)(id object))block {
  double minValue = block([self firstObject]);
  id minObject = [self firstObject];

  for (id object in self) {
    double value = block(object);
    if (value < minValue) {
      minValue = value;
      minObject = object;
    }
  }

  return minObject;
}

@end


@implementation Helpers

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

+ (UIActivityIndicatorView *)spinnerAfterCenteredLabel:(UILabel *)label {
  CGSize labelSize = [label.text sizeWithFont:label.font];
  UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  spinner.center = CGPointMake(labelSize.width + (label.frame.size.width - labelSize.width) / 2 + spinner.frame.size.width, label.center.y);
  return spinner;
}
@end
