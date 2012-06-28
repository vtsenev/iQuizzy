//
//  Question.h
//  Quizzy
//
//  Created by Vladimir Tsenev on 6/20/12.
//  Copyright (c) 2012 MentorMate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Question : NSObject

@property (nonatomic) NSInteger questionId;
@property (nonatomic, strong) NSString *questionText;
@property (nonatomic, strong) NSString *questionSection;
@property (nonatomic) NSInteger questionType;
@property (nonatomic) NSInteger questionLevel;
@property (nonatomic) NSInteger questionParentId;

@end
