//
//  FilterBarCell.h
//  OpenGLES_分屏滤镜
//
//  Created by 桑协东 on 2019/6/28.
//  Copyright © 2019 ZB_Demo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FilterBarCell : UICollectionViewCell

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL isSelect;

@end

NS_ASSUME_NONNULL_END
