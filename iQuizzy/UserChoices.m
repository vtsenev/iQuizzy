//
//  UserChoices.m
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/21/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import "UserChoices.h"
#import "DataManager.h"
#import "UserResponse.h"

@interface UserChoices ()

@property (nonatomic, strong) NSDictionary *sortedQuestionAnswers;
@property (nonatomic, strong) NSDictionary *questionsWithIds;

- (NSArray *)orderQuestionsWithRoot:(UserResponse *)root;
- (NSArray *)getRootsOfSection:(NSString *)section;
- (NSArray *)getChildrenOfQuestionWithId:(NSInteger)questionId;
- (NSDictionary *)categorizeQuestions;
- (NSString *)prepareAnswerForSingleChoiceQuestion:(Question *)question;
- (NSString *)prepareAnswerForMultipleChoiceQuestion:(Question *)question;
- (void)removeSubquestionsforQuestion:(NSNumber *)questionId withNewAnswer:(Answer *)newAnswer;
- (NSArray *)getSubquestionsOfQuestionWithId:(NSNumber *)questionId andAnswer:(NSObject *)answer;

@end

@implementation UserChoices

@synthesize questionAndAnswers;
@synthesize sortedQuestionAnswers;
@synthesize questionsWithIds;

- (id)init {
    self = [super init];
    if (self) {
        questionAndAnswers = [[NSMutableDictionary alloc] init];
        questionsWithIds = [[DataManager defaultDataManager] createQuestionTree];
    }
    return self;
}

# pragma mark - public methods

- (void)addAnswer:(Answer *)answer toSingleChoiceQuestion:(NSNumber *)questionId {
    if ([self isQuestionAnswered:questionId]) {
        [self removeSubquestionsforQuestion:questionId withNewAnswer:answer];
    }
    [self.questionAndAnswers setObject:answer forKey:questionId];
}

- (void)addAnswers:(NSArray *)answers toMultipleChoiceQuestion:(NSNumber *)questionId {
    if ([self isQuestionAnswered:questionId]) {
        [self removeSubquestionsforQuestion:questionId withNewAnswers:answers];
    }
    [self.questionAndAnswers setObject:answers forKey:questionId];
}

- (void)addAnswer:(Answer *)answer toTextQuestion:(NSNumber *)questionId {
    [self addAnswer:answer toSingleChoiceQuestion:questionId];
}

- (NSString *)prepareEmailBody {
    self.sortedQuestionAnswers = [self categorizeQuestions];
    
    NSMutableString *emailBody = [[NSMutableString alloc] init];
    NSArray *sections = [self.sortedQuestionAnswers allKeys];
    for (NSString *section in sections) {
        NSMutableArray *sectionUserResponses = [self.sortedQuestionAnswers valueForKey:section];
        
        if ([sectionUserResponses count] > 0) {
            NSArray *roots = [self getRootsOfSection:section];
            NSMutableArray *sortedSectionUserResponses = [[NSMutableArray alloc] init];
            for (UserResponse *root in roots) {
                NSArray *treeResponses = [self orderQuestionsWithRoot:root];
                [sortedSectionUserResponses addObjectsFromArray:treeResponses];
            }

            [emailBody appendString:[NSString stringWithFormat:@"%@\n", section]];
            for (UserResponse *userResponse in sortedSectionUserResponses) {
                [emailBody appendString:[NSString stringWithFormat:@"%@\n", userResponse.response]];
            }
            [emailBody appendString:@"\n"];
        }
    }
    
    return emailBody;
}

- (BOOL)isQuestionAnswered:(NSNumber *)questionId {
    return [self.questionAndAnswers objectForKey:questionId] != nil;
}

- (Answer *)fetchAnswerToSingleChoiceQuestion:(NSNumber *)questionId {
    if (![self isQuestionAnswered:questionId]) {
        return nil;
    }
    Answer *answer = [self.questionAndAnswers objectForKey:questionId];
    return answer;
}

- (NSArray *)fetchAnswersToMultipleChoiceQuestion:(NSNumber *)questionId {
    if (![self isQuestionAnswered:questionId]) {
        return nil;
    }
    NSArray *answers = [self.questionAndAnswers objectForKey:questionId];
    return answers;
}

- (BOOL)areAllQuestionsAnsweredForSection:(NSString *)section {
    NSArray *mainQuestions = [[DataManager defaultDataManager] fetchMainQuestions];
    self.sortedQuestionAnswers = [self categorizeQuestions];

    for (Question *q in mainQuestions) {
        if ([q.questionSection isEqualToString:section]) {
            if (![self areQuestionsAnsweredFromRootQuestion:q]) {
                return NO;
            }
        }
    }
    
    return YES;
}

# pragma mark - private methods

- (BOOL)areQuestionsAnsweredFromRootQuestion:(Question *)rootQuestion {
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    [stack addObject:rootQuestion];
    
    NSMutableSet *visited = [[NSMutableSet alloc] init];
    
    while ([stack count] > 0) {
        Question *q = [stack lastObject];
        [stack removeLastObject];
        
        NSNumber *questionId = [NSNumber numberWithInt:q.questionId];
        if (![self isQuestionAnswered:questionId]) {
            return NO;
        }
        
        if (![visited containsObject:questionId]) {
            [visited addObject:questionId];
            NSObject *answer = [self getAnswerOfQuestionWithId:questionId];
            NSArray *children = [self getSubquestionsOfQuestionWithId:questionId andAnswer:answer];
            for (Question *subquestion in children) {
                NSNumber *subquestionId = [NSNumber numberWithInt:subquestion.questionId];
                if (![visited containsObject:subquestionId]) {
                    [stack addObject:subquestion];
                }
            }
        }
    }
    
    return YES;
}

- (NSObject *)getAnswerOfQuestionWithId:(NSNumber *)questionId {
    Question *q = [self.questionsWithIds objectForKey:questionId];
    NSArray *sectionUserResponses = [self.sortedQuestionAnswers valueForKey:q.questionSection];
    
    for (UserResponse *u in sectionUserResponses) {
        if ([[NSNumber numberWithInt:u.questionId] isEqual:questionId]) {
            return u.answer;
        }
    }
    return nil;
}

- (NSArray *)getSubquestionsOfQuestionWithId:(NSNumber *)questionId andAnswer:(NSObject *)answer {
    Question *q = [self.questionsWithIds objectForKey:questionId];
    
    if ([answer isKindOfClass:[Answer class]]) {
        return [[DataManager defaultDataManager] fetchSubquestionsOfQuestion:q forAnswer:(Answer *)answer];
    } else if ([answer isKindOfClass:[NSArray class]]) {
        NSArray *answers = (NSArray *)answer;
        return [[DataManager defaultDataManager] fetchSubquestionsOfQuestion:q forAnswers:answers];
    }

    return nil;
}

- (NSArray *)orderQuestionsWithRoot:(UserResponse *)root {
    NSMutableArray *orderedQuestions = [[NSMutableArray alloc] init];
    
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    [stack addObject:root];
    
    NSMutableSet *visited = [[NSMutableSet alloc] init];
    
    while ([stack count] > 0) {
        UserResponse *u = [stack lastObject];
        [stack removeLastObject];
        
        [orderedQuestions addObject:u];
        
        NSNumber *questionId = [NSNumber numberWithInt:u.questionId];
        if (![visited containsObject:questionId]) {
            [visited addObject:questionId];
            
            NSArray *children = [self getChildrenOfQuestionWithId:u.questionId];
            for (UserResponse *child in children) {
                if (![visited containsObject:[NSNumber numberWithInt:child.questionId]]) {
                    [stack addObject:child];
                }
            }
        }
    }
    
    return orderedQuestions;
}

- (NSArray *)getChildrenOfQuestionWithId:(NSInteger)questionId {
    Question *q = [self.questionsWithIds objectForKey:[NSNumber numberWithInt:questionId]];
    NSArray *sectionUserResponses = [self.sortedQuestionAnswers valueForKey:q.questionSection];
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (UserResponse *u in sectionUserResponses) {
        if (u.parentId == q.questionId) {
            [result addObject:u];
        }
    }
    
    return result;
}

- (NSArray *)getRootsOfSection:(NSString *)section {
    NSMutableArray *sectionUserResponses = [self.sortedQuestionAnswers valueForKey:section];
    
    NSMutableArray *roots = [[NSMutableArray alloc] init];
    for (UserResponse *u in sectionUserResponses) {
        if (u.questionLevel == 0) {
            [roots addObject:u];
        }
    }
    return roots;
}

- (NSDictionary *)categorizeQuestions {
    NSMutableDictionary *categorizedQuestionAnswers = [[NSMutableDictionary alloc] init];
    
    NSArray *sections = [[DataManager defaultDataManager] fetchSections];
    for (NSString *sectionText in sections) {
        [categorizedQuestionAnswers setValue:[NSMutableArray array] forKey:sectionText];
    }
    
    NSArray *allQuestions = [self.questionsWithIds allValues];
    NSMutableArray *answeredQuestions = [[NSMutableArray alloc] init];
    for (Question *q in allQuestions) {
        if ([self isQuestionAnswered:[NSNumber numberWithInt:q.questionId]]) {
            [answeredQuestions addObject:q];
        }
    }

    for (Question *question in answeredQuestions) {
        NSString *questionAnswer;
        UserResponse *userResponse = [[UserResponse alloc] init];
        
        switch (question.questionType) {
            case 0:
            {
                questionAnswer = [self prepareAnswerForSingleChoiceQuestion:question];
                Answer *answer = [self.questionAndAnswers objectForKey:[NSNumber numberWithInt:question.questionId]];
                userResponse.questionLevel = question.questionLevel;
                userResponse.response = questionAnswer;
                userResponse.question = question.questionText;
                userResponse.parentId = question.questionParentId;
                userResponse.answerText = answer.answerText;
                userResponse.questionId = question.questionId;
                userResponse.answer = answer;
                break;
            }
            case 1:
            {
                questionAnswer = [self prepareAnswerForMultipleChoiceQuestion:question];
                NSArray *answers = [self.questionAndAnswers objectForKey:[NSNumber numberWithInt:question.questionId]];
                userResponse.questionLevel = question.questionLevel;
                userResponse.response = questionAnswer;
                userResponse.question = question.questionText;
                userResponse.parentId = question.questionParentId;
                NSString *combinedAnswer = [answers componentsJoinedByString:@","];
                userResponse.answerText = combinedAnswer;
                userResponse.questionId = question.questionId;
                userResponse.answer = answers;
                break;
            }
            case 2:
            {
                questionAnswer = [self prepareAnswerForSingleChoiceQuestion:question];
                userResponse.questionLevel = question.questionLevel;
                userResponse.response = questionAnswer;
                userResponse.question = question.questionText;
                userResponse.parentId = question.questionParentId;
                Answer *answer = [self.questionAndAnswers objectForKey:[NSNumber numberWithInt:question.questionId]];
                userResponse.answerText = answer.answerText;
                userResponse.questionId = question.questionId;
                break;
            }
            default:
                NSLog(@"Error - Unrecognized question type");
                break;
        }
        
        NSMutableArray *sectionQuestionAnswers = [categorizedQuestionAnswers valueForKey:question.questionSection];
        [sectionQuestionAnswers addObject:userResponse];
    }
    
    return categorizedQuestionAnswers;
}

- (NSString *)prepareAnswerForSingleChoiceQuestion:(Question *)question {
    Answer *answer = [self.questionAndAnswers objectForKey:[NSNumber numberWithInt:question.questionId]];
    NSString *result = [NSString stringWithFormat:@"%@\nYou answered: %@\n", question.questionText, answer.answerText];
    return result;
}

- (NSString *)prepareAnswerForMultipleChoiceQuestion:(Question *)question {
    NSArray *answers = [self.questionAndAnswers objectForKey:[NSNumber numberWithInt:question.questionId]];
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@\nYou replied:\n", question.questionText];
    for (Answer *a in answers) {
        [result appendString:[NSString stringWithFormat:@"%@\n", a.answerText]];
    }
    return result;
}

- (void)removeSubquestionsforQuestion:(NSNumber *)questionId withNewAnswer:(Answer *)newAnswer {
    Answer *oldAnswer = [self.questionAndAnswers objectForKey:questionId];
    if (newAnswer) {
        if (!oldAnswer || oldAnswer.answerId == newAnswer.answerId) {
            return;
        }
    }
    
    Question *question = [self.questionsWithIds objectForKey:questionId];
    NSArray *subquestions = [[DataManager defaultDataManager] fetchSubquestionsOfQuestion:question forAnswer:oldAnswer];
    if ([subquestions count] == 0) {
        return;
    }
    
    NSMutableArray *subquestionIds = [[NSMutableArray alloc] init];
    for (Question *q in subquestions) {
        NSNumber *subquestionId = [NSNumber numberWithInt:q.questionId];
        [subquestionIds addObject:subquestionId];
        [self removeSubquestionsforQuestion:subquestionId withNewAnswer:nil];
    }
    
    [self.questionAndAnswers removeObjectsForKeys:subquestionIds];
}

- (void)removeSubquestionsforQuestion:(NSNumber *)questionId withNewAnswers:(NSArray *)newAnswers {
    NSArray *oldAnswers = [self.questionAndAnswers objectForKey:questionId];
    
    Question *question = [self.questionsWithIds objectForKey:questionId];
    NSArray *subquestions = [[DataManager defaultDataManager] fetchSubquestionsOfQuestion:question forAnswers:oldAnswers];
    if ([subquestions count] == 0) {
        return;
    }
    
    NSMutableArray *subquestionIds = [[NSMutableArray alloc] init];
    for (Question *q in subquestions) {
        NSNumber *subquestionId = [NSNumber numberWithInt:q.questionId];
        [subquestionIds addObject:subquestionId];
        if (q.questionType == 0) {
            [self removeSubquestionsforQuestion:subquestionId withNewAnswer:nil];
        } else {
            [self removeSubquestionsforQuestion:subquestionId withNewAnswers:nil];
        }
    }
    
    [self.questionAndAnswers removeObjectsForKeys:subquestionIds];
}

@end