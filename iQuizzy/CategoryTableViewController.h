//
//  CategoryTableViewController.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/27/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuestionsDelegate.h"
#import "Quiz.h"

@interface CategoryTableViewController : UITableViewController <QuestionsDelegate>

@property (nonatomic, strong) Quiz *quiz;

@end
