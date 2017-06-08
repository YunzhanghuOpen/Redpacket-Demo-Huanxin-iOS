//
//  ChatWithRedPacketViewController.m
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/2/23.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import "RedPacketChatViewController.h"
#import "EaseRedBagCell.h"
#import "RedpacketTakenMessageTipCell.h"
#import "RedpacketViewControl.h"
#import "RedPacketUserConfig.h"
#import "RPRedpacketBridge.h"
#import "ChatDemoHelper.h"
#import "UserProfileManager.h"
#import "RPRedpacketUnionHandle.h"
#import "AnalysisRedpacketModel.h"
#import "RPRedpacketConstValues.h"
#ifdef AliAuthPay
#import "RPAdvertInfo.h"
#endif

#define REDPACKET_CMD_MESSAGE   @"refresh_red_packet_ack_action"

/** 红包聊天窗口 */
@interface RedPacketChatViewController () < EaseMessageCellDelegate,
                                            EaseMessageViewControllerDataSource
                                            >

@end

@implementation RedPacketChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    /** 设置用户头像大小 */
    [[EaseRedBagCell appearance] setAvatarSize:40.f];
    /** 设置头像圆角 */
    [[EaseRedBagCell appearance] setAvatarCornerRadius:20.f];
    
    if ([self.chatToolbar isKindOfClass:[EaseChatToolbar class]]) {
        
        /** 红包按钮 */
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket"]
                                 highlightedImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket_high"]
                                            title:@"红包"];
        
    }

    
    [RedPacketUserConfig sharedConfig].chatVC = self;
    
}

/** 根据userID获得用户昵称,和头像地址 */
- (RPUserInfo *)profileEntityWith:(NSString *)userId
{
    RPUserInfo *userInfo = [RPUserInfo new];

    UserProfileEntity *profile = [[UserProfileManager sharedInstance] getUserProfileByUsername:userId];
    
    if (profile) {
        
        if (profile.nickname && profile.nickname.length > 0) {
            
            userInfo.userName = profile.nickname;
            
        } else {
            
            userInfo.userName = userId;
            
        }
        
    } else {
        
        userInfo.userName = userId;
        
    }
    
    userInfo.avatar = profile.imageUrl;
    userInfo.userID = userId;
    
    return userInfo;
}

/** 长按Cell，如果是红包，则只显示删除按钮 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController canLongPressRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataArray objectAtIndex:indexPath.row];
    
    if ([object conformsToProtocol:NSProtocolFromString(@"IMessageModel")]) {
        
        id <IMessageModel> messageModel = object;
        
        if ([AnalysisRedpacketModel messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaket) {
            
            EaseMessageCell *cell = (EaseMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
            [cell becomeFirstResponder];
            
            self.menuIndexPath = indexPath;
            
            [self showMenuViewController:cell.bubbleView andIndexPath:indexPath messageType:EMMessageBodyTypeCmd];
            
            return NO;
            
        }else if ([AnalysisRedpacketModel messageCellTypeWithDict:messageModel.message.ext] == MessageCellTypeRedpaketTaken) {
            
            return NO;
        }
    }
    return [super messageViewController:viewController canLongPressRowAtIndexPath:indexPath];
}

/** 自定义红包Cell*/
- (UITableViewCell *)messageViewController:(UITableView *)tableView
                       cellForMessageModel:(id<IMessageModel>)messageModel
{
    MessageCellType type = [AnalysisRedpacketModel messageCellTypeWithDict:messageModel.message.ext];
    
    if (type == MessageCellTypeRedpaket) {
        
        /** 红包的卡片样式*/
        EaseRedBagCell *cell = [tableView dequeueReusableCellWithIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel]];
        
        if (!cell) {
            
            cell = [[EaseRedBagCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel]
                                                   model:messageModel];
            
            cell.delegate = self;
            
        }
        
        cell.model = messageModel;
        
        return cell;
        
    }else if (type == MessageCellTypeRedpaketTaken) {
        
        /** XX人领取了你的红包的卡片样式*/
        RedpacketTakenMessageTipCell *cell =  [[RedpacketTakenMessageTipCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                                  reuseIdentifier:nil];
        
        [cell configWithText:messageModel.text];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
        
    }
    
    return nil;
}

- (CGFloat)messageViewController:(EaseMessageViewController *)viewController
           heightForMessageModel:(id<IMessageModel>)messageModel
                   withCellWidth:(CGFloat)cellWidth
{
    MessageCellType type = [AnalysisRedpacketModel messageCellTypeWithDict:messageModel.message.ext];
    
    if (type == MessageCellTypeRedpaket)    {
        
        return [EaseRedBagCell cellHeightWithModel:messageModel];
        
    }else if (type == MessageCellTypeRedpaketTaken) {
        
        return [RedpacketTakenMessageTipCell heightForRedpacketMessageTipCell];
        
    }
    
    return 0;
}

/** 未读消息回执 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController shouldSendHasReadAckForMessage:(EMMessage *)message
                         read:(BOOL)read
{
    if ([AnalysisRedpacketModel messageCellTypeWithDict:message.ext] != MessageCellTypeUnknown) {
        
        return YES;
        
    }
    
    return [super shouldSendHasReadAckForMessage:message read:read];
}

- (void)messageViewController:(EaseMessageViewController *)viewController
            didSelectMoreView:(EaseChatBarMoreView *)moreView
                      AtIndex:(NSInteger)index
{
    __weak typeof(self) weakSelf = self;
    
    RPRedpacketControllerType  redpacketVCType;
    RPUserInfo *userInfo = [RPUserInfo new];
    NSArray *groupArray = [EMGroup groupWithId:self.conversation.conversationId].occupants;
    
    if (self.conversation.type == EMConversationTypeChat) {
        
            /** 小额随机红包*/
        redpacketVCType = RPRedpacketControllerTypeRand;
        userInfo = [self profileEntityWith:self.conversation.conversationId];
        
    }else {
            /** 群红包*/
        redpacketVCType = RPRedpacketControllerTypeGroup;
        userInfo.userID = self.conversation.conversationId;//如果是群红包，只要当前群ID即可
        
    }
    
    /** 发红包方法*/
    [RedpacketViewControl presentRedpacketViewController:redpacketVCType
                                         fromeController:self
                                        groupMemberCount:groupArray.count
                                   withRedpacketReceiver:userInfo
                                         andSuccessBlock:^(RPRedpacketModel *model) {
        
        [weakSelf sendRedPacketMessage:model];
        
    } withFetchGroupMemberListBlock:^(RedpacketMemberListFetchBlock completionHandle) {
        
        /** 定向红包群成员列表页面，获取群成员列表 */
        EMError *error = nil;
        EMGroup *group = [[[EMClient sharedClient] groupManager] getGroupSpecificationFromServerWithId:self.conversation.conversationId error:&error];
        
        if (error) {
            
            completionHandle(nil);
            
        } else {
            
            EMCursorResult *result = [[EMClient sharedClient].groupManager getGroupMemberListFromServerWithId:self.conversation.conversationId cursor:nil pageSize:group.occupantsCount error:&error];
            NSMutableArray *mArray = [[NSMutableArray alloc] init];
            
            for (NSString *username in result.list) {
                
                /** 创建群成员用户 */
                RPUserInfo *userInfo = [self profileEntityWith:username];
                [mArray addObject:userInfo];
            }
            
            [mArray addObject:[self profileEntityWith:group.owner]];
            completionHandle(mArray);
        }
        
    }];

}

/** 发送红包消息*/
- (void)sendRedPacketMessage:(RPRedpacketModel *)model
{
    NSDictionary *mDic = [RPRedpacketUnionHandle dictWithRedpacketModel:model isACKMessage:NO];
    NSString *messageText = [NSString stringWithFormat:@"[%@]%@", @"红包", model.greeting];
    [self sendTextMessage:messageText withExt:mDic];
}

/** 发送红包被抢的消息*/
- (void)sendRedpacketHasBeenTaked:(RPRedpacketModel *)messageModel
{
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *senderId = messageModel.sender.userID;
    NSString *conversationId = self.conversation.conversationId;
    
    //  生成红包消息体
    NSDictionary *dic = [RPRedpacketUnionHandle dictWithRedpacketModel:messageModel isACKMessage:YES];
    
    NSString *text = [NSString stringWithFormat:@"你领取了%@发的红包", messageModel.sender.userName];
    
    if (self.conversation.type == EMConversationTypeChat) {
        
        [self sendTextMessage:text withExt:dic];
        
    }else{
        
        if ([senderId isEqualToString:currentUser]) {
            
            text = @"你领取了自己的红包";
            
        }else {
            
            /** 如果不是自己发的红包，则发送抢红包消息给对方 */
            [[EMClient sharedClient].chatManager sendMessage:[self createCmdMessageWithModel:messageModel]
                                                    progress:nil
                                                  completion:nil];
            
        }
        
        EMTextMessageBody *textMessageBody = [[EMTextMessageBody alloc] initWithText:text];
        
        EMMessage *textMessage = [[EMMessage alloc] initWithConversationID:conversationId
                                                                      from:currentUser
                                                                        to:conversationId
                                                                      body:textMessageBody
                                                                       ext:dic];
        textMessage.chatType = (EMChatType)self.conversation.type;
        textMessage.isRead = YES;
        
        /** 刷新当前聊天界面 */
        [self addMessageToDataSource:textMessage progress:nil];
        
        /** 存入当前会话并存入数据库 */
        [self.conversation insertMessage:textMessage error:nil];
        
    }
}

//  生成环信CMD(透传消息)消息对象
- (EMMessage *)createCmdMessageWithModel:(RPRedpacketModel *)model
{
    NSDictionary *dict = [RPRedpacketUnionHandle dictWithRedpacketModel:model isACKMessage:YES];
    
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *toUser = model.sender.userID;
    EMCmdMessageBody *cmdChat = [[EMCmdMessageBody alloc] initWithAction:REDPACKET_CMD_MESSAGE];
    
    EMMessage *message = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId
                                                              from:currentUser
                                                                to:toUser
                                                              body:cmdChat
                                                               ext:dict];
    message.chatType = EMChatTypeChat;
    
    return message;
}

/** 抢红包事件*/
- (void)messageCellSelected:(id<IMessageModel>)model
{
    __weak typeof(self) weakSelf = self;
    
    if ([AnalysisRedpacketModel messageCellTypeWithDict:model.message.ext] == MessageCellTypeRedpaket) {
        [self.view endEditing:YES];
        
        RPRedpacketModel *messageModel = [RPRedpacketUnionHandle modelWithChannelRedpacketDic:model.message.ext
                                                                                    andSender:[self profileEntityWith:model.message.from]];
        
        [RedpacketViewControl redpacketTouchedWithMessageModel:messageModel
                                            fromViewController:self
                                            redpacketGrabBlock:^(RPRedpacketModel *messageModel) {
                                                
                                                /** 抢到红包后，发送红包被抢的消息*/
                                                if (messageModel.redpacketType != RPRedpacketTypeAmount) {
                                                    
                                                    [weakSelf sendRedpacketHasBeenTaked:messageModel];
                                                    
                                                }
                                                
                                            } advertisementAction:^(id args) {
                                                
                                                [weakSelf advertisementAction:args];
                                                
                                            }];
        
    } else {
        
        [super messageCellSelected:model];
        
    }
}

- (void)advertisementAction:(id)args
{
#ifdef AliAuthPay
    /** 营销红包事件处理*/
    RPAdvertInfo *adInfo  =args;
    switch (adInfo.AdvertisementActionType) {
        case RedpacketAdvertisementReceive:
            /** 用户点击了领取红包按钮*/
            break;
            
        case RedpacketAdvertisementAction: {
            /** 用户点击了去看看按钮，进入到商户定义的网页 */
            UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:adInfo.shareURLString]];
            [webView loadRequest:request];
            
            UIViewController *webVc = [[UIViewController alloc] init];
            [webVc.view addSubview:webView];
            [(UINavigationController *)self.presentedViewController pushViewController:webVc animated:YES];
            
        }
            break;
            
        case RedpacketAdvertisementShare: {
            /** 点击了分享按钮，开发者可以根据需求自定义，动作。*/
            [[[UIAlertView alloc]initWithTitle:nil
                                       message:@"点击「分享」按钮，红包SDK将该红包素材内配置的分享链接传递给商户APP，由商户APP自行定义分享渠道完成分享动作。"
                                      delegate:nil
                             cancelButtonTitle:@"我知道了"
                             otherButtonTitles:nil] show];
        }
            break;
            
        default:
            break;
    }
#else
    NSDictionary *dict =args;
    NSInteger actionType = [args[@"actionType"] integerValue];
    switch (actionType) {
        case 0:
            // 点击了领取红包
            break;
        case 1: {
            // 点击了去看看按钮，此处为演示
            UIViewController     *VC = [[UIViewController alloc]init];
            UIWebView *webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
            [VC.view addSubview:webView];
            NSString *url = args[@"LandingPage"];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            [webView loadRequest:request];
            [(UINavigationController *)self.presentedViewController pushViewController:VC animated:YES];
        }
            break;
        case 2: {
            // 点击了分享按钮，开发者可以根据需求自定义，动作。
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"点击「分享」按钮，红包SDK将该红包素材内配置的分享链接传递给商户APP，由商户APP自行定义分享渠道完成分享动作。" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            break;
    }

#endif
}

@end
