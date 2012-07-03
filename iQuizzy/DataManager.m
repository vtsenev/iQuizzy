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
- (NSString *)createEditableDatabase;
- (void)fetchQuestionParents;
- (NSInteger)getQuestionLevel:(NSInteger)questionId;


@end

@implementation DataManager
@synthesize currentLevel;
@synthesize questionIdsToQuestions;
@synthesize quizes;
@synthesize quizToUserChoices;

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
    self.quizToUserChoices = [NSMutableDictionary dictionary];
    
    return self;
}

# pragma mark - Database init close and request methods

- (void)initDB {
    NSString *path = [self createEditableDatabase];
    
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) {
        NSLog(@"Opening database at path: %@", path);
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

- (NSString *)createEditableDatabase {
    // Check to see if editable database already exists
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString *writableDB = [documentsDir stringByAppendingPathComponent:@"QuizData.sqlite"];
    success = [fileManager fileExistsAtPath:writableDB];
    // The editable database already exists
    if (success) {
        NSLog(@"%@", writableDB);
        NSLog(@"Success... writable database found");
        return writableDB;
    }
    
    // The editable database does not exist
    // Copy the default DB to the application Documents directory.
    NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"QuizData" ofType:@"sqlite"];
    success = [fileManager copyItemAtPath:defaultPath toPath:writableDB error:&error];
    if (!success) {
        NSLog(@"Failed to create writable database file");
        NSAssert1(0, @"Failed to create writable database file:'%@'.", [error localizedDescription]);
        return nil;
    }
    
    if([fileManager fileExistsAtPath:writableDB]){
        NSLog(@"Writable copy if DB exist");
    }
    return writableDB;
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
    const char *sqlRequest = "SELECT Quiz.QuizTitle, Quiz.QuizId FROM Quiz";
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    NSMutableArray *allQuizes = [[NSMutableArray alloc] init];
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Quiz *quiz = [[Quiz alloc] init];
            
            char *quizTitle = (char *)sqlite3_column_text(statement, 0);
            quiz.title = (quizTitle) ? [NSString stringWithUTF8String:quizTitle] : @"";
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



- (void)fetchUserResponsesForQuizWithId:(NSNumber *)quizId {
    UserChoices *userChoices = [self.quizToUserChoices objectForKey:quizId];
    NSLog(@"DataManager::fetchUserResponsesForQuizWithId\n%@", [userChoices questionAndAnswers]);
    if (!userChoices) {
        userChoices = [[UserChoices alloc] init];
        [self.quizToUserChoices setObject:userChoices forKey:quizId];
    } else {
        return;
    }
    
    NSMutableDictionary *multipleChoiceQuestionIdToAnswers = [[NSMutableDictionary alloc] init];
    
    NSString *sqlReqStr = [NSString stringWithFormat:@"SELECT AnswerId, Answer, QuestionText, QuestionType, QuestionId, SectionText from AnswersForQuestionsView where QuizId = %@", quizId];
    const char *sqlRequest = [sqlReqStr UTF8String];
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sqlRequest, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            Answer * answer = [[Answer alloc] init];
            answer.answerId = sqlite3_column_int(statement, 0);
            char *answText = (char *)sqlite3_column_text(statement, 1);
            answer.answerText = [NSString stringWithUTF8String:answText];
            
            Question *question = [[Question alloc] init];
            char *questionText = (char *)sqlite3_column_text(statement, 2);
            question.questionText = [NSString stringWithUTF8String:questionText];
            question.questionType =  sqlite3_column_int(statement, 3);
            question.questionId =  sqlite3_column_int(statement, 4);
            char *sectionText = (char *)sqlite3_column_text(statement, 5);
            question.questionSection = [NSString stringWithUTF8String:sectionText];
            
            NSNumber *questionId = [NSNumber numberWithInt:question.questionId];
            if(question.questionType == 0 || question.questionType == 2) {
                [userChoices addAnswer:answer toSingleChoiceQuestion:questionId];
            } else if (question.questionType == 1) {
                NSMutableArray *answersForQuestion = [multipleChoiceQuestionIdToAnswers objectForKey:questionId];
                if (answersForQuestion) {
                    [answersForQuestion addObject:answer];
                } else {
                    [multipleChoiceQuestionIdToAnswers setObject:[[NSMutableArray alloc] initWithObjects:answer, nil] forKey:questionId];
                }
            }
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    
    NSArray *multipleChoiceQuestions = [multipleChoiceQuestionIdToAnswers allKeys];
    for (NSNumber *questionId in multipleChoiceQuestions) {
        NSArray *answers = [multipleChoiceQuestionIdToAnswers objectForKey:questionId];
        [userChoices addAnswers:answers toMultipleChoiceQuestion:questionId];
    }
    
    NSLog(@"DataManager::QuizToUserChoices\n%@", [[self.quizToUserChoices objectForKey:quizId] questionAndAnswers]);
        
}


# pragma mark - Insert data into database

- (void)insertQuiz:(Quiz *)quiz {
    sqlite3_stmt *statement;
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO Quiz (QuizTitle) VALUES (\"%@\")", quiz.title];
    const char *insert_stmt = [insertSQL UTF8String];
    int sqlResult = sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
    
    int quizId = -1;
    
    if (sqlResult == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"Quiz %@ added", quiz.title);
            quizId = sqlite3_last_insert_rowid(database);
            quiz.quizId = [NSNumber numberWithInt:quizId];
        } else {
            NSLog(@"Failed to add");
        }
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    sqlite3_finalize(statement);
    
    UserChoices *userChoices = [[UserChoices alloc] init];
    [self.quizToUserChoices setObject:userChoices forKey:quiz.quizId];
}

- (NSInteger)insertAnswer:(Answer *)answer {
    sqlite3_stmt *statement;
    
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO Answer(Answer)  VALUES (\"%@\")", answer.answerText];
    const char *insert_stmt = [insertSQL UTF8String];
    int sqlResult = sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
    int answerId = -1;
    
    if (sqlResult == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"Answer %@ added", answer.answerText);
            answerId = sqlite3_last_insert_rowid(database);
        } else {
            NSLog(@"Failed to add answer");
        }
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    sqlite3_finalize(statement);
    
    return answerId;
}

- (NSInteger)insertAnsweredQuestion:(Question *)question forQuizId:(NSNumber *)quizId {

    sqlite3_stmt *statement;
    NSInteger answeredQuestionId = -1;
    NSString* queryStr;
    BOOL isQuestionAnswered = [self isExistQuestionId:question.questionId andQuizId:[quizId intValue]];
    
    if(!isQuestionAnswered )
    {
        queryStr = [NSString stringWithFormat:@"INSERT INTO QuizQuestionsWithAnswers(QuestionId, QuizId)  VALUES (\"%d\", \"%@\")", question.questionId, quizId];
        
    }
    else{
        queryStr = [NSString stringWithFormat:@"SELECT AnswerForQuestionId FROM QuizQuestionsWithAnswers WHERE (QuestionId = %d) AND (QuizId = %@)", question.questionId, quizId];
    }
    const char *query_stmt = [queryStr UTF8String];
    int sqlResult = sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL);
    if (sqlResult == SQLITE_OK) {
        if(!isQuestionAnswered){
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"Answered Question %@ added", question.questionText);
                answeredQuestionId = sqlite3_last_insert_rowid(database);
            }
            else {
                NSLog(@"Problem with the database:");
                NSLog(@"%d", sqlResult);
            }
        }
        else {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                answeredQuestionId = sqlite3_column_int(statement, 0);
                NSLog(@"Answered Question %@ selected", question.questionText); 
            }
        }
    } 
    else {
        NSLog(@"Failed to add or select Answered Question");
    }
    sqlite3_finalize(statement);
    
    return answeredQuestionId;
}



- (void)insertAnswer:(Answer *)answer forQuestion:(Question *)question forQuizId:(NSNumber *)quizId {
    NSInteger answerForQuestionId = [self insertAnsweredQuestion:question forQuizId:quizId];

    NSString* queryStr;
    queryStr = [NSString stringWithFormat:@"INSERT INTO AnswerForQuestion(AnswerForQuestionId, AnswerId)  VALUES (\"%d\", \"%d\")",
                answerForQuestionId, answer.answerId];
    
    BOOL isQuestionAnswered = [self isExistRowId:answerForQuestionId forColumn:@"AnswerForQuestionId" InTable:@"AnswerForQuestion"];
    
    if(isQuestionAnswered){
        if(question.questionType == 0){ 
            queryStr = [NSString stringWithFormat:@"UPDATE AnswerForQuestion SET AnswerId = %d WHERE AnswerForQuestionId = %d",
                        answer.answerId, answerForQuestionId];
        }
    }
    
    sqlite3_stmt *statement;
    const char *query_stmt = [queryStr UTF8String];
    int sqlResult = sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            if(!isQuestionAnswered){
                NSLog(@"Answer %@ for Question %@ added ", answer.answerText, question.questionText);
            }
            else {
                NSLog(@"Answer %@ for Question %@ updated ", answer.answerText, question.questionText);
            }
        } else {
            NSLog(@"Failed to add or updated Answer %@ for Question %@", answer.answerText, question.questionText);
        }
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    sqlite3_finalize(statement);
}


# pragma mark - Delete data from database

- (void)deleteQuizWithId:(NSNumber *)quizId {
    sqlite3_stmt *statement;
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM Quiz WHERE QuizId = %@", quizId];
    const char *delete_stmt = [deleteSQL UTF8String];
    int sqlResult = sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL);
    
    if (sqlResult == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"Quiz deleted");
        } else {
            NSLog(@"Failed to delete");
        }
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    sqlite3_finalize(statement);
}


- (void)deleteRowId:(NSInteger)rowId forColumn:(NSString *)column fromTable:(NSString *)table{
    
    sqlite3_stmt *statement;
    NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %d",table,column, rowId];
    const char *delete_stmt = [deleteQuery UTF8String];
    int sqlResult = sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL);
    if (sqlResult == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"rows with Id %d deleted", rowId );
        } else {
            NSLog(@"Failed to delete rows with Id: %d", rowId);
        }
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    sqlite3_finalize(statement);
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

- (void)addAnswers:(NSObject *)answerObject forQuestion:(NSNumber *)questionId forQuizId:(NSNumber *)quizId {
    UserChoices *userChoices = [self.quizToUserChoices objectForKey:quizId];
    
    if ([answerObject isKindOfClass:[Answer class]]) {
        Answer *answer = (Answer *)answerObject;
        [userChoices addAnswer:answer toSingleChoiceQuestion:questionId];
    } else if ([answerObject isKindOfClass:[NSArray class]]) {
        NSArray *answers = (NSArray *)answerObject;
        [userChoices addAnswers:answers toMultipleChoiceQuestion:questionId];
    }
}

- (NSString *)composeEmailBodyForQuizWithId:(NSNumber *)quizId {
    UserChoices *userChoices = [self.quizToUserChoices objectForKey:quizId];
    return [userChoices prepareEmailBody];
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

#pragma mark - predicates for DB

- (BOOL)isExistRowId:(NSInteger)rowId forColumn:(NSString *)column InTable:(NSString *)table{
    NSString *isExistRowIdQuery = [NSString stringWithFormat:@"SELECT count(*) FROM %@ WHERE %@ = %d  ", table, column, rowId];
    const char *isExistRowIdStmt = [isExistRowIdQuery UTF8String];
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, isExistRowIdStmt, -1, &statement, NULL);
    
    NSInteger rowCount = -1;
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            rowCount = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    return rowCount > 0;
}

- (BOOL) isExistQuestionId:(NSInteger)questionId andQuizId:(NSInteger)quizId {
    NSString *isExistRowIdQuery =
        [NSString stringWithFormat:@"SELECT count(*) FROM QuizQuestionsWithAnswers WHERE QuestionId = %d and QuizId = %d", questionId, quizId];
    const char *isExistRowIdStmt = [isExistRowIdQuery UTF8String];
    
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, isExistRowIdStmt, -1, &statement, NULL);
    NSInteger rowCount = -1;
    if (sqlResult == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            rowCount = sqlite3_column_int(statement, 0);
        }
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with the database:");
        NSLog(@"%d", sqlResult);
    }
    return rowCount > 0;
}

@end
