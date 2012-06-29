//
//  DataManager.h
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/20/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Question.h"
#import "Answer.h"
#import "UserChoices.h"

@class Quiz;

@interface DataManager : NSObject

@property (nonatomic, strong) NSMutableArray *quizes;
@property (nonatomic, strong) NSDictionary *questionIdsToQuestions;
@property (nonatomic, strong) NSMutableDictionary *quizToUserChoices;

+ (DataManager *)defaultDataManager;

- (NSDictionary *)fetchAllQuestions;
- (NSArray *)fetchMainQuestions;
- (NSArray *)fetchSubquestionsOfQuestion:(Question *)question forAnswer:(Answer *)answer;
- (NSArray *)fetchSubquestionsOfQuestion:(Question *)question forAnswers:(NSArray *)answers;
- (NSArray *)fetchQuizes;
- (NSArray *)fetchAnswersForQuestion:(Question *)question;
- (NSArray *)categorizeQuestions:(NSArray *)questions;
- (NSArray *)fetchSections;
- (void)fetchUserResponsesForQuizWithId:(NSNumber *)quizId;

- (void)addAnswers:(NSObject *)answerObject forQuestion:(NSNumber *)questionId forQuizId:(NSNumber *)quizId;
- (NSString *)composeEmailBodyForQuizWithId:(NSNumber *)quizId;
- (NSDictionary *)createQuestionTree;

- (void)insertQuiz:(Quiz *)quiz;
- (NSInteger)insertAnswer:(Answer *)answer;
- (void)insertAnswer:(Answer *)answer forQuestion:(Question *)question forQuizId:(NSNumber *)quizId;

- (void)deleteQuizWithId:(NSNumber *)quizId;

- (void)closeDB;

@end
