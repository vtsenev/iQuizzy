//
//  QuizesTableViewController.m
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/28/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import "QuizesTableViewController.h"
#import "AddQuizViewController.h"
#import "CategoryTableViewController.h"
#import "QuizDelegate.h"
#import "Quiz.h"
#import "DataManager.h"

@interface QuizesTableViewController () <QuizDelegate>

@property (nonatomic, strong) NSMutableArray *tableData;

- (BOOL)isQuizTitleUnique:(NSString *)quizTitle;

@end

@implementation QuizesTableViewController

@synthesize tableData;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableData = [NSMutableArray arrayWithArray:[[DataManager defaultDataManager] fetchQuizes]];
//    self.tableData = [NSMutableArray array];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self setTableData:nil];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"QuizCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Quiz *quiz = [self.tableData objectAtIndex:indexPath.row];
    [cell.textLabel setText:quiz.title];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Quiz *quiz = [self.tableData objectAtIndex:[indexPath row]];
        [[DataManager defaultDataManager] deleteQuizWithId:quiz.quizId];
        [self.tableData removeObjectAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

# pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"quizToCategory" sender:indexPath];
}

# pragma mark - prepare for segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"createQuiz"]) {
        AddQuizViewController *addQuizViewController = [segue destinationViewController];
        addQuizViewController.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"quizToCategory"]) {
        CategoryTableViewController *categoryTableViewController = [segue destinationViewController];
        Quiz *quiz = [self.tableData objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        [[DataManager defaultDataManager] fetchUserResponsesForQuizWithId:quiz.quizId];
        NSLog(@"QuizesTableViewController::QuizToUserChoices\n%@", [[[[DataManager defaultDataManager] quizToUserChoices] objectForKey:quiz.quizId] questionAndAnswers]);
        categoryTableViewController.quiz = quiz;
    }
}

# pragma mark - QuizDelegate methods

- (void)addedNewQuiz:(Quiz *)quiz {
    if ([self isQuizTitleUnique:quiz.title]) {
        [[DataManager defaultDataManager] insertQuiz:quiz];
        [self.tableData addObject:quiz];
        [self.tableView reloadData];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Quiz title exists" message:@"Choose a title that is unique."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

# pragma mark - private methods

- (BOOL)isQuizTitleUnique:(NSString *)quizTitle {
    for (Quiz *quiz in self.tableData) {
        if ([quiz.title isEqualToString:quizTitle]) {
            return NO;
        }
    }
    return YES;
}

@end
