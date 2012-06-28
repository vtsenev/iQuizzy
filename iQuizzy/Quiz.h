//
//  Quiz.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/28/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserChoices.h"

@interface Quiz : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *quizId;
@property (nonatomic, strong) UserChoices *userChoices;

@end
