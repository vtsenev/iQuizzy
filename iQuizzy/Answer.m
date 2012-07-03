//
//  Answer.m
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/20/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import "Answer.h"

@implementation Answer

@synthesize answerId;
@synthesize answerText;

- (NSString *)description {
    return self.answerText;
}

@end
