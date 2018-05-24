//
//  NVPictureInPictureView.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 23/05/18.
//

#import "NVPictureInPictureView.h"

#define NVAssertMainThread NSAssert([NSThread isMainThread], @"[NVPictureInPicture] NVPictureInPicture should be called from main thread only.")

typedef NS_ENUM(NSInteger, PictureInPictureVerticalPosition) {
  top = -1,
  bottom = 1
};

typedef NS_ENUM(NSInteger, PictureInPictureHorizontalPosition) {
  left = -1,
  right = 1
};

static const CGSize DefaultPictureInPictureSize = {100, 150};
static const UIEdgeInsets DefaultPictureInPictureEdgeInsets = {5,5,5,5};
static const CGFloat PanSensitivity = 1.5f;
static const CGFloat ThresholdTranslationPercentageForPictureInPicture = 0.4;
static const CGFloat AnimationDuration = 0.3f;
static const CGFloat FreeFlowTimeAfterPan = 0.05;
static const CGFloat AnimationDamping = 1.0f;

@interface NVPictureInPictureView()

@property (nonatomic) BOOL pictureInPictureActive;
@property (nonatomic) BOOL pictureInPictureEnabled;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *pipTapGesture;
@property (nonatomic) CGSize pipSize;
@property (nonatomic) CGSize fullScreenSize;
@property (nonatomic) UIEdgeInsets pipEdgeInsets;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGPoint pipCenter;
@property (nonatomic) CGPoint fullScreenCenter;
@property (nonatomic) CGPoint lastPointBeforeKeyboardToggle;
@property (nonatomic) BOOL noInteractionFlag;

@end

@implementation NVPictureInPictureView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    [self initPictureInPicture];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self != nil) {
    [self initPictureInPicture];
  }
  return self;
}

- (void)initPictureInPicture {
  [self loadValues];
  _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  _pipTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadValues {
  self.pipEdgeInsets = [self pictureInPictureEdgeInsets];
  self.pipSize = [self pictureInPictureSize];
  self.fullScreenSize = [UIScreen mainScreen].bounds.size;
  self.fullScreenCenter = CGPointMake(self.fullScreenSize.width / 2, self.fullScreenSize.height / 2);
  [self setPIPCenterWithVerticalPosition:bottom horizontalPosition:right];
}

#pragma mark Public Methods

- (void)reload {
  NVAssertMainThread;
  [self loadValues];
  if (self.isPictureInPictureActive) {
    self.bounds = CGRectMake(0, 0, self.pipSize.width, self.pipSize.height);
    [self stickPictureInPictureToEdge];
  } else {
    self.bounds = CGRectMake(0, 0, self.fullScreenSize.width, self.fullScreenSize.height);
    self.center = self.fullScreenCenter;
  }
}

- (void)enablePictureInPicture {
  NVAssertMainThread;
  if (self.isPictureInPictureEnabled) {
    NSLog(@"[NVPictureInPicture] Warning: enablePictureInPicture called when Picture in Picture is already enabled.");
    return;
  }
  self.pictureInPictureEnabled = YES;
  [self addGestureRecognizer:self.panGesture];
}

- (void)disablePictureInPicture {
  NVAssertMainThread;
  if (!self.isPictureInPictureEnabled) {
    NSLog(@"[NVPictureInPicture] Warning: disablePictureInPicture called when Picture in Picture is already disabled.");
    return;
  }
  self.pictureInPictureEnabled = NO;
  [self removeGestureRecognizer:self.panGesture];
}

- (void)startPictureInPicture {
  NVAssertMainThread;
  if (!self.isPictureInPictureEnabled) {
    NSLog(@"[NVPictureInPicture] Warning: startPictureInPicture called when Picture in Picture is disabled");
    return;
  }
  if (self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] Warning: startPictureInPicture called when view is already in picture-in-picture.");
    return;
  }
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pictureInPictureViewWillStartPictureInPicture:)]) {
    [self.delegate pictureInPictureViewWillStartPictureInPicture:self];
  }
  [self translateViewToPictureInPictureWithInitialSpeed:0.0f];
}

- (void)stopPictureInPicture {
  NVAssertMainThread;
  if (!self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] stopPictureInPicture called when view is already in full-screen.");
    return;
  }
  if (self.delegate != nil
      && [self.delegate respondsToSelector:@selector(pictureInPictureViewWillStopPictureInPicture:)]) {
    [self.delegate pictureInPictureViewWillStopPictureInPicture:self];
  }
  [self translateViewToFullScreen];
}

#pragma mark Datasource Methods

- (UIEdgeInsets)pictureInPictureEdgeInsets {
  if (@available(iOS 11.0, *)) {
    UIEdgeInsets safeAreaInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
    return UIEdgeInsetsMake(DefaultPictureInPictureEdgeInsets.top + safeAreaInsets.top,
                            DefaultPictureInPictureEdgeInsets.left + safeAreaInsets.left,
                            DefaultPictureInPictureEdgeInsets.bottom + safeAreaInsets.bottom,
                            DefaultPictureInPictureEdgeInsets.right + safeAreaInsets.right);
  }
  return DefaultPictureInPictureEdgeInsets;
}

- (CGSize)pictureInPictureSize {
  return DefaultPictureInPictureSize;
}

#pragma mark Pan Gesture Handler

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
  if (self.isPictureInPictureActive) {
    [self handlePanInPictureInPicture:gestureRecognizer];
  } else {
    [self handlePanInFullScreen:gestureRecognizer];
  }
}

- (void)handlePanInFullScreen:(UIPanGestureRecognizer *)gestureRecognizer {
  static NSInteger yMultiplier;
  static NSInteger xMultiplier;
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [self.panGesture setTranslation:CGPointZero inView:self];
    yMultiplier = 0;
    xMultiplier = 0;
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pictureInPictureViewWillStartPictureInPicture:)]) {
      [self.delegate pictureInPictureViewWillStartPictureInPicture:self];
    }
  } else {
    CGPoint translation = [gestureRecognizer translationInView:self];
    if (yMultiplier == 0 && translation.y != 0) {
      yMultiplier = translation.y / fabs(translation.y);
      xMultiplier = (translation.x == 0
                     ? yMultiplier
                     : (translation.x / fabs(translation.x)));
      [self setPIPCenterWithVerticalPosition:yMultiplier
                          horizontalPosition:xMultiplier];
    }
    CGFloat percentage = fmax(0.0,
                              PanSensitivity * yMultiplier * (translation.y / (self.fullScreenSize.height - self.pipSize.height)));
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
      if (percentage < 1.0) {
        [self updateViewWithTranslationPercentage:percentage];
      } else {
        [self updateViewWithTranslationPercentage:1.0];
      }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled
               || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
      CGFloat velocity = yMultiplier * [gestureRecognizer velocityInView:self].y;
      [self setDisplayModeWithTranslationPercentage:percentage velocity:velocity];
    }
  }
}

- (void)handlePanInPictureInPicture:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [gestureRecognizer translationInView:self];
    [self.panGesture setTranslation:CGPointZero inView:self];
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
  } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
             || gestureRecognizer.state == UIGestureRecognizerStateCancelled
             || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    self.noInteractionFlag = NO;
    CGPoint velocity = [gestureRecognizer velocityInView:self];
    CGFloat speed = fabs(velocity.y / (self.fullScreenSize.height - self.pipSize.height));
    [UIView animateWithDuration:AnimationDuration
                          delay:0
         usingSpringWithDamping:AnimationDamping
          initialSpringVelocity:speed
                        options:UIViewAnimationOptionLayoutSubviews
                     animations:^{
                       CGPoint center = self.center;
                       center.x += velocity.x * FreeFlowTimeAfterPan;
                       center.y += velocity.y * FreeFlowTimeAfterPan;
                       self.center = [self validCenterPoint:center withSize:self.pipSize];;
                     }
                     completion:^(BOOL finished) {
                     }];
  }
}

#pragma mark Helper Methods

- (CGFloat)normalizePercentage:(CGFloat)percentage WithVelocity:(CGFloat)velocity {
  return percentage + (velocity * FreeFlowTimeAfterPan) / (self.fullScreenSize.height - self.pipSize.height);
}

- (CGFloat)normalizeSpeedWithVelocity:(CGFloat)velocity withPercentage:(CGFloat)percentage {
  return fabs(velocity / (self.fullScreenSize.height - self.pipSize.height));
}

- (void)setDisplayModeWithTranslationPercentage:(CGFloat)percentage velocity:(CGFloat)velocity {
  CGFloat speed = [self normalizeSpeedWithVelocity:velocity withPercentage:percentage];
  CGFloat normalizePercentage = [self normalizePercentage:percentage WithVelocity:velocity];
  if (normalizePercentage > ThresholdTranslationPercentageForPictureInPicture) {
    [self translateViewToPictureInPictureWithInitialSpeed:speed];
  } else {
    [self translateViewToFullScreen];
  }
}

- (void)updateViewWithTranslationPercentage:(CGFloat)percentage {
  CGSize sizeDifference = CGSizeMake(self.fullScreenSize.width - self.pipSize.width,
                                     self.fullScreenSize.height - self.pipSize.height);
  CGPoint centerDifference = CGPointMake(self.fullScreenCenter.x - self.pipCenter.x,
                                         self.fullScreenCenter.y - self.pipCenter.y);
  self.bounds = CGRectMake(0,
                           0,
                           self.fullScreenSize.width - sizeDifference.width * percentage,
                           self.fullScreenSize.height - sizeDifference.height * percentage);
  self.center = CGPointMake(self.fullScreenCenter.x - centerDifference.x * percentage,
                            self.fullScreenCenter.y - centerDifference.y * percentage);
}

- (void)stickPictureInPictureToEdge {
  if (!self.isPictureInPictureActive) {
    NSLog(@"[NVPictureInPicture] Warning: stickPictureInPictureToEdge called when Picture-In-Picture is inactive.");
    return;
  }
  [UIView animateWithDuration:AnimationDuration animations:^{
    self.center = [self validCenterPoint:self.center
                                withSize:self.bounds.size];
  }];
}

- (CGPoint)validCenterPoint:(CGPoint)point
                   withSize:(CGSize)size {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if (point.x < screenSize.width / 2) {
    point.x = self.pipEdgeInsets.left + size.width / 2;
  } else {
    point.x = screenSize.width - size.width / 2 - self.pipEdgeInsets.right;
  }
  if (point.y < self.pipEdgeInsets.top + size.height / 2) {
    point.y = self.pipEdgeInsets.top + size.height / 2;
  }else if (point.y > screenSize.height - size.height / 2 - self.pipEdgeInsets.bottom - self.keyboardHeight) {
    point.y = screenSize.height - size.height / 2 - self.pipEdgeInsets.bottom - self.keyboardHeight;
  }
  return point;
}

- (void)setPIPCenterWithVerticalPosition:(PictureInPictureVerticalPosition)verticalPosition
                      horizontalPosition:(PictureInPictureHorizontalPosition)horizontalPosition{
  CGPoint center = CGPointMake(0, 0);
  if(verticalPosition == top) {
    center.y = 0 + self.pipEdgeInsets.top + self.pipSize.height / 2;
  } else {
    center.y = self.fullScreenSize.height - self.pipEdgeInsets.bottom - self.pipSize.height / 2;
  }
  if(horizontalPosition == left) {
    center.x = 0 + self.pipEdgeInsets.left + self.pipSize.width / 2;
  } else {
    center.x = self.fullScreenSize.width - self.pipEdgeInsets.right - self.pipSize.width / 2;
  }
  self.pipCenter = center;
}

#pragma mark Tap Gesture Handler

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer {
  if (self.isPictureInPictureActive) {
    if (self.delegate != nil
        && [self.delegate respondsToSelector:@selector(pictureInPictureViewWillStopPictureInPicture:)]) {
      [self.delegate pictureInPictureViewWillStopPictureInPicture:self];
    }
    [self stopPictureInPicture];
  }
}

#pragma mark Translation Methods

- (void)translateViewToPictureInPictureWithInitialSpeed:(CGFloat)speed {
  self.autoresizingMask = UIViewAutoresizingNone;
  __weak typeof(self) weakSelf = self;
  [UIView animateWithDuration:AnimationDuration
                        delay:0
       usingSpringWithDamping:AnimationDamping
        initialSpringVelocity:speed
                      options:UIViewAnimationOptionLayoutSubviews
                   animations:^{
                     [weakSelf updateViewWithTranslationPercentage:1.0f];
                   }
                   completion:^(BOOL finished) {
                     if (finished) {
                       [weakSelf addGestureRecognizer:self.pipTapGesture];
                       weakSelf.pictureInPictureActive = YES;
                       if (weakSelf.delegate != nil
                           && [weakSelf.delegate respondsToSelector:@selector(pictureInPictureViewDidStartPictureInPicture:)]) {
                         [weakSelf.delegate pictureInPictureViewDidStartPictureInPicture:self];
                       }
                     }
                   }];
}

- (void)translateViewToFullScreen {
  [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  __weak typeof(self) weakSelf = self;
  [UIView animateWithDuration:AnimationDuration animations:^{
    [weakSelf updateViewWithTranslationPercentage:0.0f];
    [weakSelf layoutIfNeeded];
  } completion:^(BOOL finished) {
    if (finished) {
      [weakSelf removeGestureRecognizer:self.pipTapGesture];
      weakSelf.pictureInPictureActive = NO;
      if (weakSelf.delegate != nil
          && [weakSelf.delegate respondsToSelector:@selector(pictureInPictureViewDidStopPictureInPicture:)]) {
        [weakSelf.delegate pictureInPictureViewDidStopPictureInPicture:self];
      }
    }
  }];
}

#pragma mark Keyboard Handler

- (void)animateWithKeyboardInfoDictionary:(NSDictionary *)info animations:(void (^)(void))animations {
  CGFloat keyboardAnimationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  NSInteger keyboardAnimationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardAnimationDuration];
  [UIView setAnimationCurve:keyboardAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  animations();
  [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  self.keyboardHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
  if (self.isPictureInPictureActive) {
    self.lastPointBeforeKeyboardToggle = self.center;
    self.noInteractionFlag = YES;
    [self animateWithKeyboardInfoDictionary:info animations:^{
      self.center = [self validCenterPoint:self.center withSize:self.bounds.size];
    }];
  }
}

- (void)keyboardWillHide:(NSNotification *)notification {
  self.keyboardHeight = 0.0f;
  NSDictionary* info = [notification userInfo];
  if (self.isPictureInPictureActive && self.noInteractionFlag) {
    [self animateWithKeyboardInfoDictionary:info animations:^{
      self.center = [self validCenterPoint:self.lastPointBeforeKeyboardToggle withSize:self.bounds.size];
    }];
    self.noInteractionFlag = NO;
  }
}

# pragma mark Rotation

- (void)handleRotationToSize:(CGSize)size {
  self.noInteractionFlag = NO;
  CGPoint originRatio = CGPointMake((self.frame.origin.x - self.pipEdgeInsets.left)
                                    / (self.fullScreenSize.width - self.pipSize.width - self.pipEdgeInsets.left - self.pipEdgeInsets.right),
                                    (self.frame.origin.y - self.pipEdgeInsets.top)
                                    / (self.fullScreenSize.height - self.pipSize.height - self.pipEdgeInsets.top - self.pipEdgeInsets.bottom));
  [self reload];
  CGPoint newCenter;
  newCenter.x = self.pipEdgeInsets.left + self.pipSize.width / 2 + originRatio.x * (size.width - self.pipSize.width - self.pipEdgeInsets.left - self.pipEdgeInsets.right);
  newCenter.y = self.pipEdgeInsets.top + self.pipSize.height / 2 + originRatio.y * (size.height - self.pipSize.height - self.pipEdgeInsets.top - self.pipEdgeInsets.bottom);
  self.center = [self validCenterPoint:newCenter withSize:self.bounds.size];
}

@end
