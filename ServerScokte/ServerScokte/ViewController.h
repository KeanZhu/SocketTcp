//
//  ViewController.h
//  ServerScokte
//
//  Created by pinglu on 16/4/8.
//  Copyright © 2016年 pinglu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"

enum{
    SocketOfflineByServer,// 服务器掉线，默认为0
    SocketOfflineByUser,  // 用户主动cut
};

@interface ViewController : UIViewController<AsyncSocketDelegate>


@end

