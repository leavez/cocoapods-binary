
// this is a demo for usage
#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>
void masonry_demo() {

    UIView *parent_view = [UIView new];
    UIView *view1 = [UIView new];
    [parent_view addSubview:view1];

    [view1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
}


