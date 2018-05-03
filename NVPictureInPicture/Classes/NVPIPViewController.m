//
//  NVPIPViewController.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPViewController.h"

static const CGSize DefaultSizeInCompactMode = {100, 150};
static const CGFloat PanSensitivity = 2.0f;
static const CGFloat ThresholdPercentForDisplayModeCompact = 0.5;
static const CGFloat AnimationDuration = 0.2f;

typedef NS_ENUM(NSInteger, NVPIPDisplayMode) {
  NVPIPDisplayModeExpanded,
  NVPIPDisplayModeCompact
};

@interface NVPIPViewController()

@property (nonatomic) NVPIPDisplayMode displayMode;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGRect compactModeFrame;
@property (nonatomic) CGRect expandedModeFrame;
@property (nonatomic) UIEdgeInsets edgeInsets;

@end

@implementation NVPIPViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgeInsets = [self edgeInsetsForDisplayModeCompact];
  self.compactModeFrame = [self frameForDisplayMode:NVPIPDisplayModeCompact];
  self.expandedModeFrame = [self frameForDisplayMode:NVPIPDisplayModeExpanded];
  self.displayMode = NVPIPDisplayModeExpanded;
  self.view.frame = self.expandedModeFrame;
  self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  [self.view addGestureRecognizer:self.panGesture];
}

- (CGRect)frameForDisplayMode:(NVPIPDisplayMode)displayMode {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (displayMode == NVPIPDisplayModeCompact) {
    return CGRectMake(screenSize.width - self.edgeInsets.right - DefaultSizeInCompactMode.width,
                      screenSize.height - self.edgeInsets.bottom - DefaultSizeInCompactMode.height,
                      DefaultSizeInCompactMode.width,
                      DefaultSizeInCompactMode.height);
  } else {
    return CGRectMake(0,
                      0,
                      screenSize.width,
                      screenSize.height);
  }
}

- (UIEdgeInsets)edgeInsetsForDisplayModeCompact {
  return UIEdgeInsetsMake(10, 10, 10, 10);
}

- (void)handlePan:(UIGestureRecognizer *)gestureRecognizer {
  if (self.displayMode == NVPIPDisplayModeExpanded) {
    [self handlePanForDisplayModeExpanded:(UIPanGestureRecognizer *)gestureRecognizer];
  } else if (self.displayMode == NVPIPDisplayModeCompact) {
    [self handlePanForDisplayModeCompact:(UIPanGestureRecognizer *)gestureRecognizer];
  }
}

- (void)handlePanForDisplayModeExpanded:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [self.panGesture setTranslation:CGPointZero inView:self.view];
  } else {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGFloat percentage = PanSensitivity * fabs(translation.y / (CGRectGetHeight(self.expandedModeFrame) - CGRectGetHeight(self.compactModeFrame)));
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged
        && percentage <= 1) {
      [self updateViewWithTranslationPercentage:percentage];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled
               || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
      [self setDisplayModeWithTranslationPercentage:percentage];
    }
  }
}

- (void)handlePanForDisplayModeCompact:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    [self.panGesture setTranslation:CGPointZero inView:self.view];
    CGPoint center = self.view.center;
    center.x += translation.x;
    center.y += translation.y;
    self.view.center = center;
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
             || gestureRecognizer.state == UIGestureRecognizerStateCancelled
             || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    [self stickCompactViewToEdge];
  }
}

- (void)updateViewWithTranslationPercentage:(CGFloat)percentage {
  CGSize sizeDifference = CGSizeMake(CGRectGetWidth(self.expandedModeFrame) - CGRectGetWidth(self.compactModeFrame),
                                     CGRectGetHeight(self.expandedModeFrame) - CGRectGetHeight(self.compactModeFrame));
  CGPoint originDifference = CGPointMake(CGRectGetMinX(self.expandedModeFrame) - CGRectGetMinX(self.compactModeFrame),
                                         CGRectGetMinY(self.expandedModeFrame) - CGRectGetMinY(self.compactModeFrame));
  self.view.frame = CGRectMake(CGRectGetMinX(self.expandedModeFrame) - originDifference.x * percentage,
                               CGRectGetMinY(self.expandedModeFrame) - originDifference.y * percentage,
                               CGRectGetWidth(self.expandedModeFrame) - sizeDifference.width * percentage,
                               CGRectGetHeight(self.expandedModeFrame) - sizeDifference.height * percentage);
}

- (void)setDisplayModeWithTranslationPercentage:(CGFloat)percentage {
  if (percentage > ThresholdPercentForDisplayModeCompact) {
    self.displayMode = NVPIPDisplayModeCompact;
  } else {
    self.displayMode = NVPIPDisplayModeExpanded;
  }
  [self animateViewToDisplayMode:self.displayMode];
}

- (void)animateViewToDisplayMode:(NVPIPDisplayMode)displayMode {
  [UIView animateWithDuration:AnimationDuration animations:^{
    self.view.frame = [self frameForDisplayMode:displayMode];
  }];
}

- (void)stickCompactViewToEdge {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGPoint center = self.view.center;
  CGPoint newCenter;
  if (center.x < screenSize.width / 2) {
    newCenter = CGPointMake(self.edgeInsets.left + CGRectGetWidth(self.view.bounds) / 2,
                                center.y);
  } else {
    newCenter = CGPointMake(screenSize.width - CGRectGetWidth(self.view.bounds) / 2 - self.edgeInsets.right,
                                center.y);
  }
  [UIView animateWithDuration:AnimationDuration animations:^{
    self.view.center = [self validateCenterPoint:newCenter];
  }];
}

- (CGPoint)validateCenterPoint:(CGPoint)point {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (point.y < self.edgeInsets.top + self.view.bounds.size.height / 2) {
    point.y = self.edgeInsets.top + self.view.bounds.size.height / 2;
  }
  if (point.y > screenSize.height - self.view.bounds.size.height / 2 - self.edgeInsets.bottom) {
    point.y = screenSize.height - self.view.bounds.size.height / 2 - self.edgeInsets.bottom;
  }
  return point;
}

- (BOOL)shouldReceivePoint:(CGPoint)point {
  return CGRectContainsPoint(self.view.frame, point);
}

@end
