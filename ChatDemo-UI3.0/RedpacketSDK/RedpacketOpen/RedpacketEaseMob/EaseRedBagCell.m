//
//  EaseRedBagCell.m
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/2/23.
//


#import "EaseRedBagCell.h"
#import "RedpacketView.h"
#import "RedPacketLuckView.h"
#import "RPRedpacketUnionHandle.h"
#import "RPRedpacketUnionHandle.h"


@interface EaseRedBagCell()

@property (nonatomic, strong) RedpacketView *redpacketView;
@property (nonatomic, strong) RedPacketLuckView *repacketLuckView;

@end


@implementation EaseRedBagCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                        model:(id<IMessageModel>)model
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier model:model];
    
    if (self) {
        self.hasRead.hidden = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (BOOL)isCustomBubbleView:(id<IMessageModel>)model
{
    return YES;
}

- (void)setCustomModel:(id<IMessageModel>)model
{
    UIImage *image = model.image;
    
    if (!image) {
        
        [self.bubbleView.imageView sd_setImageWithURL:[NSURL URLWithString:model.fileURLPath]
                                     placeholderImage:[UIImage imageNamed:model.failImageName]];
        
    } else {
        
        _bubbleView.imageView.image = image;
        
    }
    
    if (model.avatarURLPath) {
        
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:model.avatarURLPath] placeholderImage:model.avatarImage];
        
    } else {
        
        self.avatarView.image = model.avatarImage;
        
    }
}

- (void)setCustomBubbleView:(id<IMessageModel>)model
{
    _bubbleView.imageView.image = [UIImage imageNamed:@"imageDownloadFail"];
}

- (void)updateCustomBubbleViewMargin:(UIEdgeInsets)bubbleMargin model:(id<IMessageModel>)model
{
    _bubbleView.translatesAutoresizingMaskIntoConstraints = YES;
    
    AnalysisRedpacketModel *messageModel = [AnalysisRedpacketModel analysisRedpacketWithDict:model.message.ext
                                                                                 andIsSender:model.isSender];
    
    if (model.isSender) {
        
        if (messageModel.redpacketType == RPRedpacketTypeAmount) {
            
            _bubbleView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 175, 8, 116, 140);
            
        }else {
            
            _bubbleView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 273.5, 2, 213, 94);
            
        }
        
    }else {
        
        if (messageModel.redpacketType == RPRedpacketTypeAmount) {
            
            _bubbleView.frame = CGRectMake(55, 8, 116, 140);
            
        }else {
            
            _bubbleView.frame = CGRectMake(55, 2, 213, 94);
            
        }
    }
}

+ (NSString *)cellIdentifierWithModel:(id<IMessageModel>)model
{
    AnalysisRedpacketModel *messageModel = [AnalysisRedpacketModel analysisRedpacketWithDict:model.message.ext
                                                                                 andIsSender:model.isSender];
    
    if (messageModel.redpacketType == RPRedpacketTypeAmount) {
        
        return model.isSender ? @"__redPacketLuckCellSendIdentifier__" : @"__redPacketLuckCellReceiveIdentifier__";
        
    }else {
        
        return model.isSender ? @"__redPacketCellSendIdentifier__" : @"__redPacketCellReceiveIdentifier__";
        
    }
}

+ (CGFloat)cellHeightWithModel:(id<IMessageModel>)model
{
    AnalysisRedpacketModel *messageModel = [AnalysisRedpacketModel analysisRedpacketWithDict:model.message.ext
                                                                                 andIsSender:model.isSender];
    
    if (messageModel.redpacketType == RPRedpacketTypeAmount) {
        
        return [RedPacketLuckView heightForRedpacketMessageCell] + 20;
        
    }else {
        
        return [RedpacketView redpacketViewHeight] + 20;
        
    }
}

- (void)setModel:(id<IMessageModel>)model
{
    [super setModel:model];
    
    AnalysisRedpacketModel *messageModel = [AnalysisRedpacketModel analysisRedpacketWithDict:model.message.ext
                                                                                 andIsSender:model.isSender];
    
    if (messageModel.redpacketType == RPRedpacketTypeAmount) {
        
        [_redpacketView removeFromSuperview];
        _redpacketView = nil;
        [self.bubbleView.backgroundImageView addSubview:self.repacketLuckView];
        [_repacketLuckView configWithRedpacketMessageModel:messageModel];
        
    }else {
        
        [_repacketLuckView removeFromSuperview];
        _repacketLuckView = nil;
        [self.bubbleView.backgroundImageView addSubview: self.redpacketView];
        [_redpacketView configWithRedpacketMessageModel:messageModel];
        
    }
    
    /** 红包消息不显示已读 */
    _hasRead.hidden = YES;
    /** 不显示姓名 */
    _nameLabel = nil;
}

- (RedpacketView *)redpacketView
{
    if (!_redpacketView) {
        
        _redpacketView = [[RedpacketView alloc]init];
        
    }
    
    return _redpacketView;
}

- (RedPacketLuckView *)repacketLuckView
{
    if (!_repacketLuckView) {
        
        _repacketLuckView = [[RedPacketLuckView alloc]init];
        
    }
    
    return _repacketLuckView;
}

@end
