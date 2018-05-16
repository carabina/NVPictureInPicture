//
//  NVPictureInPictureViewController.h
//  NVPictureInPicture
//
//  Created by Nitesh Vijay on 10/05/18.
//

#import <UIKit/UIKit.h>

@protocol NVPictureInPictureViewControllerDelegate;

/*!
 @class    NVPictureInPictureViewController
 @abstract  NVPictureInPictureViewController is a subclass of UIViewController that can be used to present the contents floating on top of application. Subclass this class to create view controller supporting Picture in Picture. Picture in Picture can be activated either with a pan gesture or by calling -startPictureInPicture.
 @note     Picture in Picture is disabled by default. Call -enablePictureInPicture to enable it.
 */
@interface NVPictureInPictureViewController : UIViewController

/*!
 @property  delegate
 @abstract  The receiver's delegate.
 */
@property (nonatomic, weak) id<NVPictureInPictureViewControllerDelegate> delegate;

/*!
 @property  pictureInPictureActive
 @abstract  Whether or not Picture in Picture is currently active.
 */
@property(nonatomic, readonly, getter=isPictureInPictureActive) BOOL pictureInPictureActive;

/*!
 @property  pictureInPictureEnabled
 @abstract  Whether or not Picture in Picture is enabled.
 */
@property (nonatomic, readonly, getter=isPictureInPictureEnabled) BOOL pictureInPictureEnabled;

/*!
 @method    presentOnWindow:
 @param     window
 @abstract  Present NVPictureInPictureViewController
 Pass the main window of the app
 @discussion  The view will be presented modally. The view controller will be added as a child of rootViewController of window
 */
- (void)presentOnWindow:(UIWindow *)window;

/*!
 @method    dismiss
 @abstract  Dismiss NVPictureInPictureViewController
 @discussion  The view will be dismissed modally. The view and the controller will be removed from the parent.
 */
- (void)dismiss;

/*!
 @method    reload
 @abstract  Reload Picture in Picture View Controller.
 @discussion  Reloads everything from scratch. The display mode is preserved. Call reload there is any change in DataSource.
 @note      Reload is called by default on rotation.
 */
- (void)reload;

/*!
 @method    enablePictureInPicture
 @abstract  Enable Picture in Picture
 @discussion  Set pictureInPictureEnabled to YES. Enable pan gesture transition from fullscreen to Picture in Picture.
 @note      Picture in Picture is disabled by default.
 */
- (void)enablePictureInPicture;

/*!
 @method    disablePictureInPicture
 @abstract  Disable Picture in Picture
 @discussion  Set pictureInPictureEnabled to NO. Disable pan gesture transition from fullscreen to Picture in Picture.
 @note      It is recommended to first call -stopPictureInPicture if Picture in Picture is active.
 */
- (void)disablePictureInPicture;

/*!
 @method    startPictureInPicture
 @abstract  Start Picture in Picture with animation.
 @discussion  Receiver will call -pictureInPictureViewControllerWillStartPictureInPicture: before transition to Picture in Picture and -pictureInPictureViewControllerDidStartPictureInPicture: after successful transition. Client can stop Picture in Picture by calling -stopPictureInPicture. In addition the user can stop Picture in Picture through pan gesture.
 @note      startPictureInPicture will only work when Picture in Picture is enabled
 */
- (void)startPictureInPicture;

/*!
 @method    stopPictureInPicture
 @abstract  Stop Picture in Picture with animation.
 @discussion  Receiver will call -pictureInPictureViewControllerWillStopPictureInPicture: before transition to full screen and -pictureInPictureViewControllerDidStopPictureInPicture: after successful transition. Client can stop Picture in Picture by calling -stopPictureInPicture. In addition the user can stop Picture in Picture through tap on view.
 */
- (void)stopPictureInPicture;

/*!
  @method   [DataSource] pictureInPictureEdgeInsets
  @abstract Implement this method in subclass to return custom edge insets for Picture in Picture View.
  @discussion If not implemented, default insets will be used which is 10 for all edges. The Edge Insets are calculated with respect to device screen bounds.
  */
- (UIEdgeInsets)pictureInPictureEdgeInsets;

/*!
 @method   [DataSource] pictureInPictureSize
 @abstract Implement this method in subclass to return custom size for Picture in Picture View.
 @discussion If not implemented, default size will be used which is {100, 150}.
 */
- (CGSize)pictureInPictureSize;

@end

/*!
 @protocol  NVPictureInPictureViewControllerDelegate
 @abstract  A protocol for delegates of NVPictureInPictureViewController.
 */
@protocol NVPictureInPictureViewControllerDelegate <NSObject>

@optional

/*!
 @method    pictureInPictureViewControllerWillStartPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture view controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture will start.
 */
- (void)pictureInPictureViewControllerWillStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    pictureInPictureViewControllerDidStartPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture did start.
 */
- (void)pictureInPictureViewControllerDidStartPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    pictureInPictureViewControllerWillStopPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture will stop.
 */
- (void)pictureInPictureViewControllerWillStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

/*!
 @method    pictureInPictureViewControllerDidStopPictureInPicture:
 @param    pictureInPictureViewController
 The Picture in Picture controller.
 @abstract  Delegate can implement this method to be notified when Picture in Picture did stop.
 */
- (void)pictureInPictureViewControllerDidStopPictureInPicture:(NVPictureInPictureViewController *)pictureInPictureViewController;

@end
