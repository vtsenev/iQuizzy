//
//  UserChoices.h
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/21/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Answer.h"
#import "Question.h"

@interface UserChoices : NSObject

@property (nonatomic, strong) NSMutableDictionary *questionAndAnswers;

- (void)addAnswer:(Answer *)answer toSingleChoiceQuestion:(NSNumber *)questionId;
- (void)addAnswers:(NSArray *)answers toMultipleChoiceQuestion:(NSNumber *)questionId;
- (void)addAnswer:(Answer *)answer toTextQuestion:(NSNumber *)questionId;
- (NSString *)prepareEmailBody;
- (BOOL)isQuestionAnswered:(NSNumber *)questionId;
- (Answer *)fetchAnswerToSingleChoiceQuestion:(NSNumber *)questionId;
- (NSArray *)fetchAnswersToMultipleChoiceQuestion:(NSNumber *)questionId;
- (BOOL)areAllQuestionsAnsweredForSection:(NSString *)section;

@end
