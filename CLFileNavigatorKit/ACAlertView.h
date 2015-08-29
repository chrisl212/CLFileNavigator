//
//  ACAlertView.h
//  ACFileNavigator
//
//  Created by Chris on 1/19/14.
//  Copyright (c) 2014 A and C Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ACCircularProgressView.h"

@class ACAlertView;

typedef void(^ACAlertViewCompletionHandler)(ACAlertView *alertView, NSString *buttonTitle) ;

typedef NS_ENUM(NSInteger, ACAlertViewStyle)
{
    ACAlertViewStyleTextView, //Loads an alert with a text view (set text with [alertView.textView setText:]
    ACAlertViewStyleProgressView, //Loads an alert with a progress view
    ACAlertViewStyleSpinner, //Loads an alert with only a spinner
    ACAlertViewStyleTextField, //Loads an alert with a text field for input
    ACAlertViewStylePickerView, //Loads an alert with a picker view
    ACAlertViewStyleTextFieldAndPickerView, //Loads an alert with a text field and picker view
};

@protocol ACAlertViewDelegate;

@interface ACAlertView : UIView <UIPickerViewDataSource, UIPickerViewDelegate>
{
    ACAlertViewCompletionHandler completionHandler;
}

@property (strong, nonatomic) UITextView *textView; //The text view of the alert

@property (strong, nonatomic) UILabel *titleLabel; //The label where the title is displayed

@property (strong, nonatomic) ACCircularProgressView *progressView; //The progress view
@property (strong, nonatomic) UIActivityIndicatorView *spinner; //The spinner

@property (strong, nonatomic) UITextField *textField; //The text field

@property (strong, nonatomic) NSArray *pickerViewItems; //The items to be displayed by a picker view
@property (strong, nonatomic) UIPickerView *pickerView; //The picker view
@property (strong, nonatomic) UIButton *pickerViewButton; //The button clicked to open the picker view

@property (nonatomic) ACAlertViewStyle alertViewStyle; //The selected style for the alert
@property (nonatomic, getter = isHiding) BOOL hiding; //A BOOL indicating if the alert is minimized
@property (nonatomic, getter = isMoving) BOOL moving; //A BOOL indicating if the alert is being moved
@property (nonatomic) CGPoint hidingCenter; //The point that the alert was on when it was maximized
@property (weak, nonatomic) id<ACAlertViewDelegate> delegate; //The delegate for the alert

- (id)initWithTitle:(NSString *)title style:(ACAlertViewStyle)style delegate:(id<ACAlertViewDelegate>)delegate buttonTitles:(NSArray *)titles;
+ (id)alertWithTitle:(NSString *)title style:(ACAlertViewStyle)style delegate:(id<ACAlertViewDelegate>)delegate buttonTitles:(NSArray *)titles;
- (void)show; //Display the alert
- (void)dismiss; //Dismiss the alert
- (void)hide; //Mizimize the alert
- (void)showWithSelectionHandler:(ACAlertViewCompletionHandler)completion;

@end

@protocol ACAlertViewDelegate <NSObject>

@optional
- (void)alertViewDidAppear:(ACAlertView *)alertView; //The alert was presented
- (void)alertView:(ACAlertView *)alertView didClickButtonWithTitle:(NSString *)title; //The alert had the button with the title "title" clicked
- (void)alertViewDidDismiss:(ACAlertView *)alertView; //The alert was closed

@end