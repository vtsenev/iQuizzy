//
//  QuestionsTableViewController.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/27/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuestionsDelegate.h"

@class Quiz;
@interface QuestionsTableViewController : UITableViewController

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, weak) id<QuestionsDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary *answers;
@property (nonatomic, strong) Quiz *quiz;

@end
