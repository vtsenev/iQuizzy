//
//  AnswerTableViewController.m
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/27/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import "AnswerTableViewController.h"
#import "Answer.h"
#import "DataManager.h"
#import "Question.h"

@interface AnswerTableViewController ()

@property (strong, nonatomic) NSMutableArray *chosenAnswers;

- (void)done:(id)sender;
- (void)selectOldAnswers;

@end

@implementation AnswerTableViewController

@synthesize answers;
@synthesize isQuestionSingleChoice;
@synthesize chosenAnswers;
@synthesize delegate;
@synthesize question;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.chosenAnswers = [NSMutableArray array];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self setAnswers:nil];
    [self setChosenAnswers:nil];
    [self setQuestion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setTitle:self.question.questionText];
    
    if (self.isQuestionSingleChoice) {
        [self.tableView setAllowsMultipleSelection:NO];        
    } else {
        [self.tableView setAllowsMultipleSelection:YES];
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
        [self.navigationItem setRightBarButtonItem:doneBtn];
    }
    
    [self selectOldAnswers];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.answers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AnswerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Answer *answer = [self.answers objectAtIndex:[indexPath row]];
    [cell.textLabel setText:answer.answerText];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Answer *chosenAnswer = [self.answers objectAtIndex:indexPath.row];

    if (!self.isQuestionSingleChoice) {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [self.chosenAnswers addObject:chosenAnswer];
    }
    else {
        NSArray *subquestions = [[DataManager defaultDataManager] fetchSubquestionsOfQuestion:self.question forAnswer:chosenAnswer];
        
        if ([self.delegate respondsToSelector:@selector(didSubmitAnswer:withSubquestions:forQuestion:)]) {
            [self.delegate didSubmitAnswer:chosenAnswer withSubquestions:subquestions forQuestion:self.question];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isQuestionSingleChoice) {
        [tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]].accessoryType = UITableViewCellAccessoryNone;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.isQuestionSingleChoice) {
        [self.chosenAnswers removeObject:[self.answers objectAtIndex:indexPath.row]];
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    }
}

# pragma mark - private methods

- (void)done:(id)sender {
    if ([self.chosenAnswers count] > 0) {
        NSArray *subquestions = [[DataManager defaultDataManager] fetchSubquestionsOfQuestion:self.question forAnswers:self.chosenAnswers];
        if ([self.delegate respondsToSelector:@selector(didSubmitAnswer:withSubquestions:forQuestion:)]) {
            [self.delegate didSubmitAnswer:self.chosenAnswers withSubquestions:subquestions forQuestion:self.question];
        }
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select answer" message:@"No answer is selected." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)selectOldAnswers {
    UserChoices *userChoices = [DataManager defaultDataManager].userChoices;
    NSNumber *questionId = [NSNumber numberWithInt:self.question.questionId];
    BOOL isQuestionAnswered = [userChoices isQuestionAnswered:questionId];
    
    if (isQuestionAnswered) {
        NSArray *previousAnswers;
        if (self.isQuestionSingleChoice) {
            Answer *previousAnswer = [userChoices fetchAnswerToSingleChoiceQuestion:questionId];
            previousAnswers = [NSArray arrayWithObject:previousAnswer];
        } else {
            previousAnswers = [userChoices fetchAnswersToMultipleChoiceQuestion:questionId];
        }
        
        NSIndexPath *answerIndexPath;
        for (Answer *answer in previousAnswers) {
            for (int i = 0; i< self.answers.count; ++i) {
                Answer* currAnswer = [self.answers objectAtIndex:i];
                if([currAnswer.answerText isEqualToString:answer.answerText]){
                    answerIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.tableView selectRowAtIndexPath:answerIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                    [self.tableView cellForRowAtIndexPath:answerIndexPath].accessoryType = UITableViewCellAccessoryCheckmark;
                    [self.chosenAnswers addObject:currAnswer];
                    break;
                }
            }
        }
    }
}

@end
