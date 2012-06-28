//
//  QuizDelegate.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/28/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Quiz.h"

@protocol QuizDelegate <NSObject>

- (void)addedNewQuiz:(Quiz *)quiz;

@end
