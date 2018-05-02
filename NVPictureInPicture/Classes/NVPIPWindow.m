//
//  NVPIPWindow.m
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 02/05/18.
//

#import "NVPIPWindow.h"

@implementation NVPIPWindow

- (instancetype)initWithFrame:(CGRect)frame
                  windowLevel:(CGFloat)windowLevel {
  self = [super initWithFrame:frame];
  if (self != nil) {
    self.windowLevel =  windowLevel;
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = YES;
  }
  return self;
}

@end
