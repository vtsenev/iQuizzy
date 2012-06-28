//
//  AnswerTableViewController.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/27/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnswerDelegate.h"

@class Question;

@interface AnswerTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *answers;
@property (nonatomic, strong) Question *question;
@property (nonatomic) BOOL isQuestionSingleChoice;
@property (nonatomic, weak) id<AnswerDelegate> delegate;

@end
