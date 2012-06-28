//
//  AddQuizViewController.m
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/28/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import "AddQuizViewController.h"
#import "Quiz.h"

@interface AddQuizViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *quizTitleField;

- (IBAction)addQuiz:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@implementation AddQuizViewController
@synthesize quizTitleField;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [self setQuizTitleField:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark - IBAction methods

- (IBAction)addQuiz:(id)sender {
    if (![self.quizTitleField.text isEqualToString:[NSString string]]) {
        Quiz *quiz = [[Quiz alloc] init];
        quiz.title = self.quizTitleField.text;
        quiz.userChoices = nil;
        
        if ([self.delegate respondsToSelector:@selector(addedNewQuiz:)]) {
            [self.delegate addedNewQuiz:quiz];
        }
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Title" message:@"Enter a quiz title." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

# pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (![textField.text isEqualToString:[NSString string]]) {
        [self addQuiz:nil];
    }
    return [textField resignFirstResponder];
}

@end
