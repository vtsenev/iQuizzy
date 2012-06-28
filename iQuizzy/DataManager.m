//
//  DataManager.m
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/20/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <sqlite3.h>
#import "DataManager.h"
#import "Question.h"
#import "Quiz.h"

static DataManager *defaultDataManager = nil;

@interface DataManager () {
    sqlite3 *database;
}

@property (nonatomic) NSInteger currentLevel;

- (void)initDB;

- (void)fetchQuestionParents;
- (NSInteger)getQuestionLevel:(NSInteger)questionId;

@end

@implementation DataManager
@synthesize userChoices;
@synthesize currentLevel;
@synthesize questionIdsToQuestions;
@synthesize quizes;

# pragma mark - Singleton core implementation

+ (DataManager *)defaultDataManager {
    if (!defaultDataManager) {
        @synchronized(self) {
            if (!defaultDataManager) {
                defaultDataManager = [[super allocWithZone:NULL] init];
            }
        }
    }
    return defaultDataManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self defaultDataManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)init {
    if (defaultDataManager) {
        return defaultDataManager;
    }
    self = [super init];
    
    [self initDB];
    
    return self;
}

# pragma mark - Database init close and request methods

- (void)initDB {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"QuizData" ofType:@"sqlite"];
    
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) {
        NSLog(@"Opening database");
    } else {
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database: %s'.", sqlite3_errmsg(database));
    }
}

- (void)closeDB {
    if (sqlite3_close(database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database: ‘%s’.", sqlite3_errmsg(database));
    }
}

- (NSDictionary *)fetchAllQuestions {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    const char *sqlRequest = "SELECT q.QuestionText, q.QuestionType, s.SectionText, q.QuestionId FROM Question q join Section s on q.QuestionSectionId = s.sectionId";
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Question *question = [[Question alloc] init];
            
            char *questionText = (char *)sqlite3_column_text(statement, 0);
            question.questionText = (questionText) ? [NSString stringWithUTF8String:questionText] : @"";
            question.questionType = sqlite3_column_int(statement, 1);
            char *questionSection = (char *)sqlite3_column_text(statement, 2);
            question.questionSection = (questionSection) ? [NSString stringWithUTF8String:questionSection] : @"";
            question.questionId = sqlite3_column_int(statement, 3);
            
            NSNumber *questionId = [NSNumber numberWithInt:question.questionId];
            [result setObject:question forKey:questionId];
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    return result;
}

- (NSArray *)fetchMainQuestions {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    const char *sqlRequest = "SELECT q.QuestionText, q.QuestionType, s.SectionText, q.QuestionId FROM Question q join Section s on q.QuestionSectionId = s.sectionId where q.QuestionParentId is null";
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Question *question = [[Question alloc] init];
            
            char *questionText = (char *)sqlite3_column_text(statement, 0);
            question.questionText = (questionText) ? [NSString stringWithUTF8String:questionText] : @"";
            question.questionType = sqlite3_column_int(statement, 1);
            char *questionSection = (char *)sqlite3_column_text(statement, 2);
            question.questionSection = (questionSection) ? [NSString stringWithUTF8String:questionSection] : @"";
            question.questionId = sqlite3_column_int(statement, 3);
            
            [result addObject:question];
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    return result;
}

- (NSArray *)fetchSubquestionsOfQuestion:(Question *)question forAnswer:(Answer *)answer {
    NSMutableArray *result = [[NSMutableArray alloc] init];

    sqlite3_stmt *statement;
    const char *sqlRequest = "SELECT q.QuestionText, q.QuestionType, s.SectionText, q.QuestionId FROM Question q join Section s on q.QuestionSectionId = s.sectionId join QuestionParent qp on qp.ParentId = q.QuestionParentId where (qp.QuestionId = ?) and (qp.AnswerId = ?)";
    
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);

    if(sqlResult == SQLITE_OK) {
        sqlite3_bind_int(statement,1,question.questionId);
        sqlite3_bind_int(statement,2,answer.answerId);
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Question *question = [[Question alloc] init];

            char *questionText = (char *)sqlite3_column_text(statement, 0);
            question.questionText = (questionText) ? [NSString stringWithUTF8String:questionText] : @"";
            question.questionType = sqlite3_column_int(statement, 1);
            char *questionSection = (char *)sqlite3_column_text(statement, 2);
            question.questionSection = (questionSection) ? [NSString stringWithUTF8String:questionSection] : @"";
            question.questionId = sqlite3_column_int(statement, 3);

            [result addObject:question];
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    return result;
}

- (NSArray *)fetchSubquestionsOfQuestion:(Question *)question forAnswers:(NSArray *)answers {
    NSMutableArray *subquestions = [[NSMutableArray alloc] init];
    for (Answer *a in answers) {
        NSArray *subquestionsForCurrentAnswer = [self fetchSubquestionsOfQuestion:question forAnswer:a];
        [subquestions addObjectsFromArray:subquestionsForCurrentAnswer];
    }
    
    return subquestions;
}

- (NSArray *)fetchAnswersForQuestion:(Question *)question {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *statement;
    const char *sqlRequest = "SELECT a.Answer, a.AnswerId FROM Answer a join QuestionParent qp on qp.AnswerId = a.AnswerId join Question q on q.QuestionId = qp.QuestionId where q.QuestionId = ?";
    
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    if(sqlResult == SQLITE_OK) {
        sqlite3_bind_int(statement, 1, question.questionId);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Answer *answer = [[Answer alloc] init];
            
            char *answerText = (char *)sqlite3_column_text(statement, 0);
            answer.answerText = (answerText) ? [NSString stringWithUTF8String:answerText] : @"";
            answer.answerId = sqlite3_column_int(statement, 1);
            
            [result addObject:answer];
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    return result;
}

- (NSArray *)fetchSections {
    if (userChoices == nil) {
        userChoices = [[UserChoices alloc] init];
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *statement;
    const char *sqlRequest = "SELECT s.sectionText FROM Section s";
    
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    if(sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *section = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
            [result addObject:section];
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    return result;    
}

- (void)fetchQuestionParents {
    const char *sqlRequest = "SELECT q.QuestionId, qp.QuestionId from Question q join QuestionParent qp on q.QuestionParentId = qp.ParentId";
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            NSInteger questionId = sqlite3_column_int(statement, 0);
            NSInteger parentId = sqlite3_column_int(statement, 1);
            
            Question *q = [self.questionIdsToQuestions objectForKey:[NSNumber numberWithInt:questionId]];
            q.questionParentId = parentId;
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
}

- (NSArray *)fetchQuizes {
    # warning sqlRequest show be updated
    const char *sqlRequest = "SELECT Quiz.Title, Quiz.QuizId FROM Quiz";
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    NSMutableArray *allQuizes = [[NSMutableArray alloc] init];
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Quiz *quiz = [[Quiz alloc] init];
            
            char *questionText = (char *)sqlite3_column_text(statement, 0);
            quiz.title = (questionText) ? [NSString stringWithUTF8String:questionText] : @"";
            NSInteger quizId = sqlite3_column_int(statement, 1);
            quiz.quizId = [NSNumber numberWithInt:quizId];
            
            [allQuizes addObject:quiz];
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    return allQuizes;
}

# pragma mark - Add user response and sort responses

- (NSArray *)categorizeQuestions:(NSArray *)questions{
    NSMutableArray *categorizedQuestions = [[NSMutableArray alloc]init];
    NSArray *sections = [self fetchSections];
    
    for (NSString *section in sections) {
        NSArray *values = [NSArray arrayWithObjects:section, [NSMutableArray array], nil];
        NSArray *keys = [NSArray arrayWithObjects:@"sectionTitle", @"questions", nil];
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        [categorizedQuestions addObject:dict];
    }
    
    for (Question *q in questions) {
        for(NSDictionary *dict in categorizedQuestions){
            if([[dict valueForKey:@"sectionTitle"] isEqualToString:q.questionSection]){
                [((NSMutableArray *)[dict valueForKey:@"questions"]) addObject:q];
            }
        }
    }
    
    return categorizedQuestions;
}

- (void)addAnswers:(NSObject *)answerObject forQuestion:(NSNumber *)questionId {
    if ([answerObject isKindOfClass:[Answer class]]) {
        Answer *answer = (Answer *)answerObject;
        [self.userChoices addAnswer:answer toSingleChoiceQuestion:questionId];
    } else if ([answerObject isKindOfClass:[NSArray class]]) {
        NSArray *answers = (NSArray *)answerObject;
        [self.userChoices addAnswers:answers toMultipleChoiceQuestion:questionId];
    }
}

- (NSString *)composeEmailBody {
    return [self.userChoices prepareEmailBody];
}

- (NSDictionary *)createQuestionTree {
    self.questionIdsToQuestions = [self fetchAllQuestions];
    [self fetchQuestionParents];

    NSArray *allQuestions = [self.questionIdsToQuestions allValues];
    for (Question *q in allQuestions) {
        if (q.questionParentId == 0) {
            q.questionLevel = 0;
        } else {
            q.questionLevel = [self getQuestionLevel:q.questionParentId] + 1;
        }
    }
    
    return self.questionIdsToQuestions;
}

- (NSInteger)getQuestionLevel:(NSInteger)questionId {
    Question *parent = [self.questionIdsToQuestions objectForKey:[NSNumber numberWithInt:questionId]];
    
    if (parent.questionParentId == 0) {
        return 0;
    }
    else {
        return [self getQuestionLevel:parent.questionParentId] + 1;
    }
}

@end
