//
//  MainViewController.m
//  AllegroTime
//
//  Created by Dmitry Sokurenko on 25.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MainViewController.h"
#import "CrossingListController.h"
#import "CrossingScheduleController.h"
#import "CrossingMapController.h"

const int MainView_CrossingStateSection = 0;
const int MainView_CrossingStateSection_TitleRow = 0;
const int MainView_CrossingStateSection_StateRow = 1;
const int MainView_CrossingStateSection_StateDetailsRow = 2;
const int MainView_CrossingActionsSection = 1;
const int MainView_CrossingActionsSection_ScheduleRow = 0;
const int MainView_CrossingActionsSection_MapRow = 1;

@implementation MainViewController {
  NSTimer *timer;
}

@synthesize locationState;
@synthesize locationManager;
@synthesize timer;

#pragma mark - lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
//  self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Data/Images/Screen Shot 2012-04-18 at 18.01.08.png"]];
//  self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/Screen Shot 2012-04-18 at 18.02.10.png"]];
  self.title = @"Время Аллегро";
  self.locationState = CLLocationManager.locationServicesEnabled ? LocationStateSearching : LocationStateNotAvailable;
  self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Статус" style:UIBarButtonItemStyleBordered target:nil action:nil];

  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
  [self.navigationController setToolbarHidden:YES animated:YES];
  [self startStuff];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [self stopStuff];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - table view stuff

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case MainView_CrossingStateSection:
      return 3;
    case MainView_CrossingActionsSection:
      return 2;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CrossingNameCellID = @"crossing-name-cell";
  static NSString *CrossingStateCellID = @"crossing-state-cell";
  static NSString *CrossingStateDetailsCellID = @"crossing-state-details-cell";
  static NSString *DefaultWithTriangleCellID = @"default-with-triangle-cell";

  UITableViewCell *cell;
  switch (indexPath.section) {
    case MainView_CrossingStateSection:
      switch (indexPath.row) {
        case MainView_CrossingStateSection_TitleRow:
          cell = [tableView dequeueReusableCellWithIdentifier:CrossingNameCellID];
          if (!cell) {
            cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CrossingNameCellID];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          }
          cell.textLabel.text = @"Переезд";
          cell.detailTextLabel.text = model.currentCrossing.name;
          break;
        case MainView_CrossingStateSection_StateRow:
        {
          cell = [tableView dequeueReusableCellWithIdentifier:CrossingStateDetailsCellID];
          if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CrossingStateDetailsCellID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, [Helper tableViewCellWidth] - 20, 18)];
            topLabel.tag = 1;
            topLabel.textAlignment = UITextAlignmentCenter;
            topLabel.font = [UIFont systemFontOfSize:17];
            topLabel.textColor = [UIColor blackColor];
            topLabel.backgroundColor = [UIColor clearColor];

            UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 22, [Helper tableViewCellWidth] - 20, 18)];
            bottomLabel.tag = 2;
            bottomLabel.textAlignment = UITextAlignmentCenter;
            bottomLabel.font = [UIFont systemFontOfSize:14];
            bottomLabel.textColor = [UIColor grayColor];
            bottomLabel.backgroundColor = [UIColor clearColor];

            [cell.contentView addSubview:topLabel];
            [cell.contentView addSubview:bottomLabel];
          }

          UILabel *topLabel = (UILabel *) [cell viewWithTag:1];
          UILabel *bottomLabel = (UILabel *) [cell viewWithTag:2];

          Closing *nextClosing = model.currentCrossing.nextClosing;

          topLabel.text = [NSString stringWithFormat:@"Аллегро пройдет в %@", [Helper formatTimeInMunutesAsHHMM:nextClosing.timeInMinutes]];
          if (model.currentCrossing.state == CrossingStateClosed) {
            bottomLabel.text = [NSString stringWithFormat:@"Переезд закрыли в %@", [Helper formatTimeInMunutesAsHHMM:nextClosing.stopTimeInMinutes]];
          } else {
            bottomLabel.text = [NSString stringWithFormat:@"Переезд закроют в %@", [Helper formatTimeInMunutesAsHHMM:nextClosing.stopTimeInMinutes]];
          }

          break;
        }

        case MainView_CrossingStateSection_StateDetailsRow:
          cell = [tableView dequeueReusableCellWithIdentifier:CrossingStateCellID];
          if (!cell) {
            cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CrossingStateCellID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
          }

          cell.backgroundColor = [UIColor whiteColor];
          cell.textLabel.textColor = [UIColor blackColor];

          switch (model.currentCrossing.state) {
            case CrossingStateClear:
              cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-GreenGradient.png"]];
              cell.textLabel.textColor = [UIColor whiteColor];
              cell.textLabel.text = @"До закрытия более часа";
              break;
            case CrossingStateSoon:
              cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-GreenGradient.png"]];
              cell.textLabel.textColor = [UIColor whiteColor];
              cell.textLabel.text = [NSString stringWithFormat:@"До закрытия около %i минут", [Helper roundToFive:model.currentCrossing.minutesTillNextClosing]];
              break;
            case CrossingStateVerySoon:
              cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-RedGradient.png"]];
              cell.textLabel.textColor = [UIColor whiteColor];
              cell.textLabel.text = [NSString stringWithFormat:@"До закрытия около %i минут", [Helper roundToFive:model.currentCrossing.minutesTillNextClosing]];
              break;
            case CrossingStateClosing:
              cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-RedGradient.png"]];
              cell.textLabel.textColor = [UIColor whiteColor];
              cell.textLabel.text = @"Сейчас закроют";
              break;
            case CrossingStateClosed:
              cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-RedGradient.png"]];
              cell.textLabel.textColor = [UIColor whiteColor];
              cell.textLabel.text = @"Переезд закрыт";
              break;
            case CrosingsStateJustOpened:
              cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Data/Images/TableViewCell-YellowGradient.png"]];
              cell.textLabel.textColor = [UIColor darkGrayColor];
              cell.textLabel.text = @"Переезд только что открыли";
              break;
          }

          break;
      }
      break;
    case MainView_CrossingActionsSection:
      cell = [tableView dequeueReusableCellWithIdentifier:DefaultWithTriangleCellID];
      if (!cell) {
        cell = [UITableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DefaultWithTriangleCellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }

      switch (indexPath.row) {
        case 0:
          cell.textLabel.text = @"Расписание Аллегро";
          break;
        case 1:
          cell.textLabel.text = @"Карта переездов";
          break;
      }
  }

  return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  switch (section) {
    case MainView_CrossingStateSection:
      switch (locationState) {
        case LocationStateSearching:
        {
          UIView *header = [[UIView alloc] initWithFrame:CGRectZero];

          UILabel *label = [Helper labelForTableViewFooter];
          label.frame = CGRectMake(5, 0, tableView.bounds.size.width - 30, 30);
          label.text = @"Поиск ближайшего переезда...";


          UIActivityIndicatorView *spinner = [Helper spinnerAfterCenteredLabel:label];
          [spinner startAnimating];


          [header addSubview:label];
          [header addSubview:spinner];

          return header;
        }
        default:
          return nil;
      }
  }
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  switch (section) {
    case MainView_CrossingStateSection:
      switch (locationState) {
        case LocationStateSearching:
          return 30;
        default:
          return 0;
      }
  }
  return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  if (section == MainView_CrossingStateSection && locationState == LocationStateNotAvailable)
    return @"Не удалось определить ближайший переезд";
  if (section == MainView_CrossingActionsSection)
    return @"Показаны только перекрытия перездов для прохода Аллегро, переезд может оказаться закрытым раньше или открытым позже из-за прохода электричек и товарных поездов";
  return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.section) {
    case MainView_CrossingStateSection:
      switch (indexPath.row) {
        case MainView_CrossingStateSection_TitleRow:
        {
          CrossingListController *crossingsController = [[CrossingListController alloc] initWithStyle:UITableViewStyleGrouped];
          crossingsController.target = self;
          crossingsController.action = @selector(changeSelectedCrossing:);
          crossingsController.accessoryType = UITableViewCellAccessoryCheckmark;
          [self.navigationController pushViewController:crossingsController animated:YES];
        }
      }
      break;
    case MainView_CrossingActionsSection:
      switch (indexPath.row) {
        case MainView_CrossingActionsSection_ScheduleRow:
        {
          CrossingListController *crossingsController = [[CrossingListController alloc] initWithStyle:UITableViewStyleGrouped];
          crossingsController.target = self;
          crossingsController.action = @selector(showScheduleForCrossing:);
          crossingsController.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          [self.navigationController pushViewController:crossingsController animated:YES];
          break;
        }
        case MainView_CrossingActionsSection_MapRow:
        {
          CrossingMapController *mapController = [[CrossingMapController alloc] init];
          [self.navigationController pushViewController:mapController animated:YES];
        }
      }
  }
}

#pragma mark - handlers

- (void)timerTicked:(NSTimer *)theTimer {
  NSLog(@"timerTicked блять %@", [NSDate new]);
  [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
  // * check if the data are fresh enought: abs(newLocation.timestamp.timeIntervalSinceNow) > 60.0
  // * unsubscribe from the further updates if the GPS is used once the precise and recent data are gathered

  self.locationState = LocationStateSet;

  model.closestCrossing = [model crossingClosestTo:newLocation];
  if (!model.selectedCrossing)
    [self.tableView reloadData];

  NSLog(@"newLocation acc:%.1f coord:%f,%f %@", newLocation.horizontalAccuracy, newLocation.coordinate.latitude, newLocation.coordinate.longitude, model.closestCrossing);
}

- (void)showScheduleForCrossing:(Crossing *)crossing {
  CrossingScheduleController *scheduleController = [[CrossingScheduleController alloc] initWithStyle:UITableViewStyleGrouped];
  scheduleController.crossing = crossing;
  [self.navigationController pushViewController:scheduleController animated:YES];
}

- (void)changeSelectedCrossing:(Crossing *)crossing {
  if (crossing.isClosest) {
    model.selectedCrossing = nil;
    model.closestCrossing = crossing;
  }
  else {
    model.selectedCrossing = crossing;
  }

  [self.navigationController popViewControllerAnimated:YES];
  [self.tableView reloadData];
}

- (void)applicationDidEnterBackground {
  [self stopStuff];
}

- (void)applicationWillEnterForeground {
  [self startStuff];
}

- (void)stopStuff {
  [locationManager stopMonitoringSignificantLocationChanges];
  [timer invalidate];
}

- (void)startStuff {
  if (CLLocationManager.locationServicesEnabled) {
    [self.locationManager startMonitoringSignificantLocationChanges];
  }

  timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timerTicked:) userInfo:nil repeats:YES];
  timer.fireDate = [Helper nextFullMinuteDate];
}

#pragma mark - properties

- (void)setLocationState:(LocationState)aLocationState {
  if (locationState != aLocationState) {
    locationState = aLocationState;
    [self.tableView reloadData];
  }
}

- (CLLocationManager *)locationManager {
  if (!locationManager) {
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
//    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
//    locationManager.distanceFilter = 300;
  }
  return locationManager;
}

@end
