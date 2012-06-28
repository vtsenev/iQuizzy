//
//  QuestionsDelegate.h
//  iQuizzy
//
//  Created by Vladimir Tsenev on 6/28/12.
//  Copyright (c) 2012 Vladimir Tsenev. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QuestionsDelegate <NSObject>

@optional
- (void) didSubmitQuestions:(NSArray *)questions withAnswers:(NSDictionary *)answers forSection:(NSString *)section;

@end
