//
//  AddQuizViewController.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/28/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuizDelegate.h"

@interface AddQuizViewController : UIViewController

@property (nonatomic, weak) id<QuizDelegate> delegate;

@end
