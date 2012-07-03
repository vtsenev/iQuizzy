//
//  QuestionsTableViewController.m
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/27/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import "QuestionsTableViewController.h"
#import "DataManager.h"
#import "AnswerDelegate.h"
#import "AnswerTableViewController.h"
#import "TextChoiceViewController.h"
#import "Quiz.h"

@interface QuestionsTableViewController () <AnswerDelegate>

@property (nonatomic) NSUInteger questionIndex;
@property (nonatomic, strong) NSDictionary *questionDict;
@property (nonatomic) BOOL willGoBackToRootView;

- (NSArray *)getSubquestionsOfQuestion:(Question *)question;
- (void)removeAllSubquestionsOfQuestion:(Question *)root;

@end

@implementation QuestionsTableViewController
@synthesize title;
@synthesize tableData;
@synthesize answers;
@synthesize questionIndex;
@synthesize questionDict;
@synthesize delegate;
@synthesize willGoBackToRootView;
@synthesize quiz;

- (void)viewDidUnload {
    
    [self setTitle:nil];
    [self setAnswers:nil];
    [self setTableData:nil];
    [self setQuestionDict:nil];
    [self setQuiz:nil];
    [super viewDidUnload];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:self.title];
    
    questionDict = [[DataManager defaultDataManager] createQuestionTree];
    
    if (!self.tableData) {
        NSArray *allQuestions = [questionDict allValues];
        self.tableData = [NSMutableArray array];
        for (Question *q in allQuestions) {
            if (q.questionParentId == 0 && [q.questionSection isEqualToString:self.title]) {
                [self.tableData addObject:q];
            }
        }
    }
    
    if (!self.answers) {
        self.answers = [[NSMutableDictionary alloc] init];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.willGoBackToRootView = YES;
    for (Question *questionInTable in self.tableData) {
        Question *question = [questionDict objectForKey:[NSNumber numberWithInt:questionInTable.questionId]];
        questionInTable.questionParentId = question.questionParentId;
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.willGoBackToRootView) {
        if([self.delegate respondsToSelector:@selector(didSubmitQuestions:withAnswers:forSection:)]){
            [self.delegate didSubmitQuestions:self.tableData withAnswers:self.answers forSection:self.title];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableData count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"QuestionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Question *question = [self.tableData objectAtIndex:[indexPath row]];
    
    [cell.textLabel setText:question.questionText];
    
    UserChoices *userChoices = [[[DataManager defaultDataManager] quizToUserChoices] objectForKey:self.quiz.quizId];
    if ([userChoices isQuestionAnswered:[NSNumber numberWithInt:question.questionId]]) {
        cell.detailTextLabel.text = [self.answers valueForKey:question.questionText];
    } else {
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Question *question = [self.tableData objectAtIndex:[indexPath row]];
    self.willGoBackToRootView = NO;
    if (question.questionType == 0 || question.questionType == 1) {
        [self performSegueWithIdentifier:@"questionToAnswers" sender:nil];
        self.questionIndex = [indexPath row];
    } else if (question.questionType == 2) {
        [self performSegueWithIdentifier:@"questionWithTextAnswer" sender:nil];
    }
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*) indexPath {
    Question *question = [self.tableData objectAtIndex:[indexPath row]];
    
    CGSize questionTextSize = [question.questionText sizeWithFont:[UIFont boldSystemFontOfSize:17.0] constrainedToSize:CGSizeMake(260.0f, 480.0f) lineBreakMode:UILineBreakModeWordWrap];
    CGSize answerTextSize = [[self.answers valueForKey:question.questionText] sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(260.0f, 480.0f) lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat newCellHeight = questionTextSize.height + answerTextSize.height + 30;
    
    return newCellHeight;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Question *q = [self.tableData objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    if ([[segue identifier] isEqualToString:@"questionToAnswers"]) {
        AnswerTableViewController *answerTableViewController = [segue destinationViewController];
        if (q.questionType == 0) {
            answerTableViewController.isQuestionSingleChoice = YES;
        } else if (q.questionType == 1) {
            answerTableViewController.isQuestionSingleChoice = NO;
        }
        answerTableViewController.answers = [[DataManager defaultDataManager] fetchAnswersForQuestion:q];
        answerTableViewController.question = q;
        answerTableViewController.delegate = self;
        answerTableViewController.quiz = self.quiz;
    } else if ([[segue identifier] isEqualToString:@"questionWithTextAnswer"]) {
        TextChoiceViewController *textChoiceViewController = [segue destinationViewController];
        textChoiceViewController.question = q;
        textChoiceViewController.delegate = self;
        textChoiceViewController.quiz = self.quiz;
    }
}

#pragma mark - AnswerDelegate Methods

- (void)didSubmitAnswer:(NSObject *)answerObject withSubquestions:(NSArray *)subquestions forQuestion:(Question *)question {
    if ([self.answers valueForKey:question.questionText]) {
        [self removeAllSubquestionsOfQuestion:question];
    }
    
    if (question.questionType == 0) {
        Answer *answer = (Answer *)answerObject;
        [self.answers setValue:answer.answerText forKey:question.questionText];
        [[DataManager defaultDataManager] insertAnswer:answer forQuestion:question forQuizId:self.quiz.quizId];
        [[DataManager defaultDataManager] addAnswers:answerObject forQuestion:[NSNumber numberWithInt:question.questionId] forQuizId:self.quiz.quizId];
        
    } else if (question.questionType == 1) {
        
        NSInteger answerForQuestionId = [[DataManager defaultDataManager] insertAnsweredQuestion:question forQuizId:self.quiz.quizId];
        [[DataManager defaultDataManager] deleteRowId:answerForQuestionId forColumn:@"AnswerForQuestionId" fromTable:@"AnswerForQuestion"];
        [[DataManager defaultDataManager] addAnswers:answerObject forQuestion:[NSNumber numberWithInt:question.questionId] forQuizId:self.quiz.quizId];
        
        NSArray *theAnswers = (NSArray *)answerObject;
        NSString *concatenatedAnswers = [theAnswers componentsJoinedByString: @", "];
        [self.answers setValue:concatenatedAnswers forKey:question.questionText];
        
        for (Answer *a in theAnswers) {
            [[DataManager defaultDataManager] insertAnswer:a forQuestion:question forQuizId:self.quiz.quizId];

        }
    }
    
    NSUInteger index = self.questionIndex + 1;
    for (Question *q in subquestions) {
        [self.tableData insertObject:q atIndex:index];
        ++index;
    }
    
    [self.tableView reloadData];
}

- (void)didSubmitTextAnswer:(Answer *)textAnswer forQuestion:(Question *)question {
    [[DataManager defaultDataManager] addAnswers:textAnswer forQuestion:[NSNumber numberWithInt:question.questionId] forQuizId:self.quiz.quizId];
    [self.answers setValue:textAnswer.answerText forKey:question.questionText];
    
    [self.tableView reloadData];
}

# pragma mark - private methods

- (void)removeAllSubquestionsOfQuestion:(Question *)root {
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    [stack addObject:root];
    
    NSMutableSet *visited = [[NSMutableSet alloc] init];
    
    while ([stack count] > 0) {
        Question *q = [stack lastObject];
        [stack removeLastObject];
        
        if (q.questionId != root.questionId) {
            [self.tableData removeObjectIdenticalTo:q];
        }
        
        NSNumber *questionId = [NSNumber numberWithInt:q.questionId];
        if (![visited containsObject:questionId]) {
            [visited addObject:questionId];
            
            NSArray *children = [self getSubquestionsOfQuestion:q];
            for (Question *child in children) {
                if (![visited containsObject:[NSNumber numberWithInt:child.questionId]]) {
                    [stack addObject:child];
                }
            }
        }
    }
}

- (NSArray *)getSubquestionsOfQuestion:(Question *)question {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (Question *q in self.tableData) {
        if (q.questionParentId == question.questionId) {
            [result addObject:q];
        }
    }
    
    return result;
}

@end
