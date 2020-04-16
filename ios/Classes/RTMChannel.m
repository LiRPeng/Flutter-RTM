//
//  RTMChannel.m
//  agora_rtm
//
//  Created by LY on 2019/8/16.
//

#import "RTMChannel.h"

@implementation RTMChannel

- (instancetype) initWithClientIndex:(NSNumber *)clientIndex channelId:(NSString *)channelId messenger:(id)messenger kit:(AgoraRtmKit*)kit {
  self = [super init];
  if (self) {
    _clientIndex = clientIndex;
    _channelId = channelId;
    _channel = [kit createChannelWithId:channelId delegate:self];
    if (nil == _channel) {
      return nil;
    }
    _messenger = messenger;
    NSString *channelName = [NSString stringWithFormat:@"io.agora.rtm.client%@.channel%@", [clientIndex stringValue], channelId];
    _eventChannel = [FlutterEventChannel eventChannelWithName:channelName binaryMessenger:_messenger];
    if (nil == _eventChannel) {
      return nil;
    }
    
    [_eventChannel setStreamHandler:self];
  }
  return self;
}

- (void) dealloc {
  _clientIndex = nil;
  _channelId = nil;
  _channel = nil;
  _eventChannel = nil;
  _messenger = nil;
}

#pragma - FlutterStreamHandler
- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
  _eventSink = events;
  return nil;
}

- (void) sendChannelEvent:(NSString *)name params:(NSDictionary*)params {
  if (_eventSink) {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:params];
    dict[@"event"] = name;
    _eventSink([dict copy]);
  }
}


#pragma - AgoraRtmChannelDelegate
- (void)channel:(AgoraRtmChannel *)channel attributeUpdate:(NSArray<AgoraRtmChannelAttribute *> *)attributes{
     NSError *error = nil;
         if (attributes == nil) {
             [self sendChannelEvent:@"onAttributesUpdated" params:@{
                 @"attributes": ""
             }];
             return
         }
         NSData *jsonData = [NSJSONSerialization dataWithJSONObject:attributes options:NSJSONWritingPrettyPrinted error:&error];
         if (jsonData == nil) {
             [self sendChannelEvent:@"onAttributesUpdated" params:@{
                 @"attributes": ""
             }];
             return
         }
         NSString *str= [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
         if (str == nil) {
             [self sendChannelEvent:@"onAttributesUpdated" params:@{
                 @"attributes": ""
             }];
             return
         }
         [self sendChannelEvent:@"onAttributesUpdated" params:@{
             @"attributes": str
         }];
}

- (void)channel:(AgoraRtmChannel *)channel memberCount:(int)count{
    [self sendChannelEvent:@"onMemberCountUpdated" params:@{
        @"memberCount": [NSNumber numberWithInt:count]
    }];
}

- (void)channel:(AgoraRtmChannel *)channel memberJoined:(AgoraRtmMember *)member {
  [self sendChannelEvent:@"onMemberJoined" params:@{@"userId": member.userId, @"channelId": member.channelId}];
}

- (void)channel:(AgoraRtmChannel *)channel memberLeft:(AgoraRtmMember *)member {
  [self sendChannelEvent:@"onMemberLeft" params:@{@"userId": member.userId, @"channelId": member.channelId}];
}
- (void)channel:(AgoraRtmChannel *)channel messageReceived:(AgoraRtmMessage *)message fromMember:(AgoraRtmMember *)member {
  [self sendChannelEvent:@"onMessageReceived" params:@{@"userId": member.userId,
           @"channelId": member.channelId,
           @"message":
              @{@"text":message.text,
                @"ts": @(message.serverReceivedTs),
                @"offline": @(message.isOfflineMessage)}
                                                     }];
}

@end
