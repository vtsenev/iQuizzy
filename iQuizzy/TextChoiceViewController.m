//
//  TextChoiceViewController.m
//  Quizzy
//
//  Created by Victor Hristoskov on 6/21/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import "TextChoiceViewController.h"
#import "Answer.h"
#import "DataManager.h"

@interface TextChoiceViewController ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UILabel *questionTitle;
@property (strong, nonatomic) IBOutlet UITextView *answerTextView;

- (void)getPreviousAnswer;
- (IBAction)cancelTextChoice:(id)sender;
- (IBAction)submitTextChoice:(id)sender;

@end

@implementation TextChoiceViewController

@synthesize questionTitle;
@synthesize answerTextView;
@synthesize question;
@synthesize delegate;
@synthesize contentView;

- (void)viewDidUnload {
    [self setAnswerTextView:nil];
    [self setQuestion:nil];
    [self setQuestionTitle:nil];
    [self setDelegate:nil];
    [self setContentView:nil];
    [self setAnswerTextView:nil];
    [super viewDidUnload];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    [self.answerTextView becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setTitle:self.question.questionText];
    [self getPreviousAnswer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - IBAction Methods

- (IBAction)cancelTextChoice:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)submitTextChoice:(id)sender {
    Answer *answer = [[Answer alloc] init];
    answer.answerId = NSIntegerMax;
    answer.answerText = self.answerTextView.text;

    if([self.delegate respondsToSelector:@selector(didSubmitTextAnswer:forQuestion:)]) {
        [self.delegate didSubmitTextAnswer:answer forQuestion:self.question];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - additional functionality

-(void) keyboardWillShow {
    [self moveAllComponentsWithAnimationForOffset:-80.0f];
}

-(void) keyboardWillHide {
    [self moveAllComponentsWithAnimationForOffset:+80.0f];
}

-(void) moveAllComponentsWithAnimationForOffset:(CGFloat)offset {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y + offset,
                                        self.contentView.frame.size.width, self.contentView.frame.size.height);
    [UIView commitAnimations];
}

- (void)getPreviousAnswer {
    UserChoices *userChoices = [DataManager defaultDataManager].userChoices;
    NSNumber *questionId = [NSNumber numberWithInt:self.question.questionId];
    BOOL isQuestionAnswered = [userChoices isQuestionAnswered:questionId];
    
    if (isQuestionAnswered) {
        Answer *previousAnswer = [userChoices fetchAnswerToSingleChoiceQuestion:questionId];
        [self.answerTextView setText:[previousAnswer answerText]];
    }
}

@end
