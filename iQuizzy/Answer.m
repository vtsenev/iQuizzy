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

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToAnswer:other];
}

- (BOOL)isEqualToAnswer:(Answer *)anAnswer {
    if (self.answerId != anAnswer.answerId)
        return NO;
    return YES;
}

@end
