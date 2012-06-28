//
//  AnswerDelegate.h
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/20/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Question.h"
#import "Answer.h"

@protocol AnswerDelegate <NSObject>

@optional
- (void)didSubmitAnswer:(NSObject *)answerObject withSubquestions:(NSArray *)subquestions forQuestion:(Question *)question;
- (void)didSubmitTextAnswer:(Answer *)textAnswer forQuestion:(Question *)question;

@end
