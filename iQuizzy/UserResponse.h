//
//  UserResponse.h
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/22/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Answer.h"

@interface UserResponse : NSObject

@property (nonatomic, strong) NSString *response;
@property (nonatomic, strong) NSString *question;
@property (nonatomic, strong) NSString *answerText;
@property (nonatomic) NSInteger questionLevel;
@property (nonatomic) NSInteger parentId;
@property (nonatomic) NSInteger questionId;
@property (nonatomic, strong) NSObject *answer;

@end
