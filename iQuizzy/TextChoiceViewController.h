//
//  TextChoiceViewController.h
//  Quizzy
//
//  Created by Victor Hristoskov on 6/21/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnswerDelegate.h"

@class Question;
@class Quiz;

@interface TextChoiceViewController : UIViewController<UITextFieldDelegate>

@property(strong, nonatomic) Question *question;
@property(strong, nonatomic) Quiz *quiz;
@property(weak, nonatomic) id<AnswerDelegate> delegate;

@end
