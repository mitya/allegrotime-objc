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
#import "LogViewController.h"

const int StateSection = 0;
const int ActionsSection = 1;

@interface MainViewController ()
@property (nonatomic, assign) LocationState locationState;
@property (nonatomic, strong) NSTimer *timer;
@property (strong, nonatomic) IBOutlet UITableViewCell *crossingCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *stateCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *stateDetailsCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *showScheduleCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *showMapCell;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *stateCellTopLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *stateCellBottomLabel;
@property (strong, nonatomic) IBOutlet UIView *stateSectionHeader;
@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation MainViewController
@synthesize locationState;
@synthesize timer;
@synthesize crossingCell;
@synthesize stateCell;
@synthesize stateDetailsCell;
@synthesize showScheduleCell;
@synthesize showMapCell;
@synthesize stateCellTopLabel;
@synthesize stateCellBottomLabel;
@synthesize stateSectionHeader;
@synthesize spinner;


#pragma mark - lifecycle

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Время Аллегро";
  self.locationState = CLLocationManager.locationServicesEnabled ? LocationStateSearching : LocationStateNotAvailable;
  self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Статус" style:UIBarButtonItemStyleBordered target:nil action:nil];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Лог" style:UIBarButtonItemStyleBordered target:self action:@selector(showLog)];

  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(closestCrossingChanged) name:NXClosestCrossingChanged object:nil];
  [self.spinner startAnimating];
}

- (void)viewDidUnload {
  [self setShowMapCell:nil];
  [self setShowScheduleCell:nil];
  [self setStateDetailsCell:nil];
  [self setStateCellTopLabel:nil];
  [self setStateCellBottomLabel:nil];
  [self setStateCell:nil];
  [self setCrossingCell:nil];
  [self setStateSectionHeader:nil];
  [self setSpinner:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.tableView reloadData];
  [self.navigationController setToolbarHidden:YES animated:YES];

  timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(timerTicked:) userInfo:nil repeats:YES];
  timer.fireDate = [Helper nextFullMinuteDate];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [timer invalidate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return MXAutorotationPolicy(interfaceOrientation);
}


#pragma mark - table view stuff

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == StateSection) return 3;
  if (section == ActionsSection) return 2;
  else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell;
  
  if (indexPath.section == StateSection && indexPath.row == 0) {
    cell = self.crossingCell;
    cell.detailTextLabel.text = model.currentCrossing.name;          
  } else if (indexPath.section == StateSection && indexPath.row == 1) {
    cell = self.stateCell;
    Closing *nextClosing = model.currentCrossing.nextClosing;    
    stateCellTopLabel.text = [NSString stringWithFormat:@"Аллегро пройдет в %@", [Helper formatTimeInMunutesAsHHMM:nextClosing.timeInMinutes]];
    if (model.currentCrossing.state == CrossingStateClosed) {
      stateCellBottomLabel.text = [NSString stringWithFormat:@"Переезд закрыли в %@", [Helper formatTimeInMunutesAsHHMM:nextClosing.stopTimeInMinutes]];
    } else {
      stateCellBottomLabel.text = [NSString stringWithFormat:@"Переезд закроют в %@", [Helper formatTimeInMunutesAsHHMM:nextClosing.stopTimeInMinutes]];
    }      
  } else if (indexPath.section == StateSection && indexPath.row == 2) {        
    cell = self.stateDetailsCell;    
    
    MXSetGradientForCell(cell, model.currentCrossing.color);
    
    CrossingState state = model.currentCrossing.state;
    NSString *message;
    if (state == CrossingStateClear) {
      message = @"До закрытия более часа";
    } else if (state == CrossingStateSoon) {
      message = [NSString stringWithFormat:@"До закрытия около %i минут", [Helper roundToFive:model.currentCrossing.minutesTillNextClosing]];
    } else if (state == CrossingStateVerySoon) {
      message = [NSString stringWithFormat:@"До закрытия около %i минут", [Helper roundToFive:model.currentCrossing.minutesTillNextClosing]];
    } else if (state == CrossingStateClosing) {
      message = @"Сейчас закроют";
    } else if (state == CrossingStateClosed) {
      message = @"Переезд закрыт";
    } else if (state == CrosingsStateJustOpened) {
      message = @"Переезд только что открыли";
    }
    cell.textLabel.text = message;
    
  } else if (indexPath.section == ActionsSection) {
    if (indexPath.row == 0) cell = self.showScheduleCell;
    if (indexPath.row == 1) cell = self.showMapCell;
  }

  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  if (section == StateSection && locationState == LocationStateNotAvailable)
    return @"Не удалось определить ближайший переезд";
  if (section == ActionsSection)
    return @"Показаны только перекрытия перездов для прохода Аллегро, переезд может оказаться закрытым раньше или открытым позже из-за прохода электричек и товарных поездов";
  else 
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
  if (cell == crossingCell) {    
    CrossingListController *crossingsController = [[CrossingListController alloc] initWithStyle:UITableViewStyleGrouped];
    crossingsController.target = self;
    crossingsController.action = @selector(changeSelectedCrossing:);
    crossingsController.accessoryType = UITableViewCellAccessoryCheckmark;
    [self.navigationController pushViewController:crossingsController animated:YES];
  } else if (cell == showScheduleCell) {
    CrossingListController *crossingsController = [[CrossingListController alloc] initWithStyle:UITableViewStyleGrouped];
    crossingsController.target = self;
    crossingsController.action = @selector(showScheduleForCrossing:);
    crossingsController.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self.navigationController pushViewController:crossingsController animated:YES];
  } else if (cell == showMapCell) {
    CrossingMapController *mapController = [[CrossingMapController alloc] init];
    [self.navigationController pushViewController:mapController animated:YES];
  }
}

#pragma mark - handlers

- (void)timerTicked:(NSTimer *)theTimer {
  MXConsoleFormat(@"timerTicked %@", MXFormatDate([NSDate date], @"HH:mm:ss"));
  [self.tableView reloadData];
}

- (void)closestCrossingChanged {
  if (self.locationState == LocationStateSet) {
    NSArray *indexPaths = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:2 inSection:0], nil];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
  } else {
    self.locationState = LocationStateSet;
    [self.tableView reloadData];
  }
}

- (void)showScheduleForCrossing:(Crossing *)crossing {
  CrossingScheduleController *scheduleController = [[CrossingScheduleController alloc] initWithStyle:UITableViewStyleGrouped];
  scheduleController.crossing = crossing;
  [self.navigationController pushViewController:scheduleController animated:YES];
}

- (void)showLog {
  LogViewController *logController = [[LogViewController alloc] init];
  [self.navigationController pushViewController:logController animated:YES];
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

#pragma mark - properties

- (void)setLocationState:(LocationState)aLocationState {
  if (locationState != aLocationState) {
    locationState = aLocationState;
    [self.tableView reloadData];
    
    if (locationState == LocationStateSet)
      [self.spinner stopAnimating];
  }
}

@end
