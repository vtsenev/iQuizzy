//
//  CategoryTableViewController.m
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/27/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "CategoryTableViewController.h"
#import "QuestionsTableViewController.h"
#import "DataManager.h"
#import "UserChoices.h"

@interface CategoryTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, strong) NSMutableDictionary *openQuestions;
@property (nonatomic, strong) NSMutableDictionary *answersForSection;

- (IBAction)sendEmail;
- (void)initializeQuestionsAndAnswers;

@end

@implementation CategoryTableViewController

@synthesize tableData;
@synthesize openQuestions;
@synthesize answersForSection;
@synthesize quiz;

- (void)viewDidUnload {
    [super viewDidUnload];
    [self setTableData:nil];
    [self setOpenQuestions:nil];
    [self setAnswersForSection:nil];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableData = [[DataManager defaultDataManager] fetchSections];

    [self.navigationItem setTitle:self.quiz.title];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeQuestionsAndAnswers];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Question categories";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CategoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSString *section = [self.tableData objectAtIndex:[indexPath row]];
    UserChoices *userChoices = [[[DataManager defaultDataManager] quizToUserChoices] objectForKey:self.quiz.quizId];
    BOOL areAllQuestionsAnswered = [userChoices areAllQuestionsAnsweredForSection:section];
    if (areAllQuestionsAnswered) {
        [cell.imageView setImage:[UIImage imageNamed:@"tick"]];
    } else {
        [cell.imageView setImage:[UIImage imageNamed:@"question_mark"]];
    }
    
    [cell.textLabel setText:section];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"categoryQuestions" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"categoryQuestions"]) {
        QuestionsTableViewController *questionsTableViewController = [segue destinationViewController];
        NSString *section = [self.tableData objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        questionsTableViewController.title = section;
        questionsTableViewController.delegate = self;
        questionsTableViewController.quiz = self.quiz;

        NSArray *questions = [self.openQuestions valueForKey:section];
        if (questions) {
            questionsTableViewController.tableData = [NSMutableArray arrayWithArray:questions];
            NSLog(@"+++++++++++++++++\nCategory\nAnsweres For Scetion: %@", self.answersForSection); 
            questionsTableViewController.answers = [self.answersForSection valueForKey:section];
            NSLog(@"+++++++++++++++++\nCategory\nAnsweres: %@", questionsTableViewController.answers);
        }
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

# pragma mark - private methods

- (IBAction)sendEmail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        
        NSString *messageBody = [[DataManager defaultDataManager] composeEmailBodyForQuizWithId:self.quiz.quizId];
        [mailer setMessageBody:messageBody isHTML:NO];
        
        [self presentModalViewController:mailer animated:YES];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Failure"
                                    message:@"Your device doesn't support the composer sheet"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)initializeQuestionsAndAnswers {
    UserChoices *userChoices = [[[DataManager defaultDataManager] quizToUserChoices] objectForKey:self.quiz.quizId];
    NSLog(@"==========================\nCategory::initializeQuestionAndAnswers\n%@",[[[[DataManager defaultDataManager] quizToUserChoices] objectForKey:self.quiz.quizId] questionAndAnswers]);
    
    if (userChoices) {
        NSMutableDictionary *testDict = userChoices.questionAndAnswers;
        NSArray *keys = [testDict allKeys];
        for (NSNumber *qId in keys) {
            NSLog(@"questionId = %@, answer = %@", qId, [testDict objectForKey:qId]);
        }
        
        self.openQuestions = [userChoices fetchOpenQuestions];
        self.answersForSection = [userChoices fetchAnswersToQuestions];
    } else {
        self.openQuestions = [NSMutableDictionary dictionary];
        self.answersForSection = [NSMutableDictionary dictionary];
    }
    
}

#pragma mark - QuestionDelegate Methods

- (void) didSubmitQuestions:(NSArray *)questions withAnswers:(NSDictionary *)answers forSection:(NSString *)section {
    [self.openQuestions setValue:questions forKey:section];
    [self.answersForSection setValue:answers forKey:section];
    
    NSLog(@"Answers %@", answers);
    NSLog(@"AnswersForSection %@", self.answersForSection);
    
}

@end
