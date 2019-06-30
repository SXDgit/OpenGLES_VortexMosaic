//
//  FilterBar.h
//  OpenGLES_分屏滤镜
//
//  Created by 桑协东 on 2019/6/28.
//  Copyright © 2019 ZB_Demo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FilterBar;

@protocol FilterBarDelegate <NSObject>

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index;

@end

@interface FilterBar : UIView

@property (nonatomic, strong) NSArray <NSString *> *itemList;

@property (nonatomic, weak) id<FilterBarDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
