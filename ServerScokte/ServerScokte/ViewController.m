//
//  ViewController.m
//  ServerScokte
//
//  Created by pinglu on 16/4/8.
//  Copyright © 2016年 pinglu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (strong ,nonatomic) AsyncSocket* serverSocket;
@property (strong ,nonatomic) AsyncSocket* clientSocket;

@property (strong ,nonatomic) UITableView* tableView;
@property (strong ,nonatomic) UITextField* textField;

@end

@implementation ViewController
{
    NSMutableArray* _stockDataSource;
    NSMutableArray* sourceData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _stockDataSource = [[NSMutableArray alloc]init];
    sourceData = [[NSMutableArray alloc] init];
    
//    创建服务器的套接字对象
    _serverSocket = [[AsyncSocket alloc]initWithDelegate:self];
    //等待客户端连接
    UInt16 port = 8083;
    [_serverSocket acceptOnPort:port error:nil];
    
    _clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
    NSString* host = @"192.168.3.3";
    UInt16 port2 = 8085;
    [_clientSocket connectToHost:host onPort:port2 withTimeout:-1 error:nil];
    
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-70) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    UIView* titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 40)];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, [UIScreen mainScreen].bounds.size.width, 30)];
    label.text = @"聊天空间";
    label.font = [UIFont systemFontOfSize:20];
    label.textAlignment = NSTextAlignmentCenter;
    [titleView addSubview:label];
    _tableView.tableHeaderView =titleView;
    
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-50, [UIScreen mainScreen].bounds.size.width, 50)];
    _textField.delegate = self;
    _textField.layer.masksToBounds = YES;
    _textField.layer.cornerRadius = 25;
    _textField.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:_textField];
    
    UITapGestureRecognizer* tapgest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    _tableView.userInteractionEnabled = YES;
    [_tableView addGestureRecognizer:tapgest];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    
    CGRect rect = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat h = rect.size.height;
    
    [UIView animateWithDuration:0.25 animations:^{
        _textField.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height-50-h, [UIScreen mainScreen].bounds.size.width, 50);
    }];
    
}

- (void)keyboardWillHide:(NSNotification *)notif {

    [UIView animateWithDuration:0.25 animations:^{
        _textField.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height-50, [UIScreen mainScreen].bounds.size.width, 50);
    }];
}

-(void)tapAction
{
    [_textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([_clientSocket isConnected]==NO) {
        _clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
        NSString* host = @"192.168.3.3";
        UInt16 port2 = 8085;
        [_clientSocket connectToHost:host onPort:port2 withTimeout:-1 error:nil];
        return NO;
    }
    //    ======================连接成功============
    NSString* message = textField.text;
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    //    发送数据
    [_clientSocket writeData:data withTimeout:60 tag:200];
    NSDictionary* dict = @{@"key":@"1",@"value":textField.text};
    [sourceData addObject:dict];
    textField.text = @"";
    [_tableView reloadData];
    return YES;
}

#pragma mark - AsyncSocketDelegate
////有新的连接时，回调这个方法
-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    //???
    [_stockDataSource addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:300];
    
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString* message = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"------1------%@",message);
    NSDictionary* dict = @{@"key":@"2",@"value":message};
    [sourceData addObject:dict];
    [_tableView reloadData];
    [sock readDataWithTimeout:-1 tag:300];
}



//接收数据
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"服务器连接成功，host：%@ portable：%d",host,port);
    
    
}
//连接失败的时候
-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"服务器被连接失败：%@",[err localizedDescription]);
}


#pragma mark - UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return sourceData.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSDictionary *dict = sourceData[indexPath.row];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
    label.text =dict[@"value"];
    if ([dict[@"key"] intValue] == 1) {
        label.textAlignment = NSTextAlignmentLeft;
    }else
    {
        label.textAlignment = NSTextAlignmentRight;
    }
    [cell.contentView addSubview:label];
    
    return cell;
}

@end
