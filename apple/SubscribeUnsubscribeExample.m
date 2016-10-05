//  Diffusion Client Library for iOS and OS X - Examples
//
//  Copyright (C) 2015, 2016 Push Technology Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "SubscribeUnsubscribeExample.h"

@import Diffusion;

@interface SubscribeUnsubscribeExample (PTDiffusionTopicStreamDelegate) <PTDiffusionTopicStreamDelegate>
@end

@implementation SubscribeUnsubscribeExample {
    PTDiffusionSession* _session;
}

-(void)start {
    NSLog(@"Connecting...");

    [PTDiffusionSession openWithURL:_url
                      configuration:_sessionConfiguration
                  completionHandler:^(PTDiffusionSession *session, NSError *error)
    {
        if (!session) {
            NSLog(@"Failed to open session: %@", error);
            return;
        }

        // At this point we now have a connected session.
        NSLog(@"Connected.");

        // Set ivar to maintain a strong reference to the session.
        _session = session;

        // Register self as the fallback handler for topic updates.
        [session.topics addFallbackTopicStreamWithDelegate:self];

        // Wait 5 seconds and then subscribe.
        [self performSelector:@selector(subscribe:) withObject:session afterDelay:5.0];
    }];
}

static NSString *const _TopicSelectorExpression = @"*Assets//";

-(void)subscribe:(const id)object {
    PTDiffusionSession *const session = object;

    NSLog(@"Subscribing...");
    [session.topics subscribeWithTopicSelectorExpression:_TopicSelectorExpression
                                       completionHandler:^(NSError * const error)
    {
        if (error) {
            NSLog(@"Subscribe request failed. Error: %@", error);
        } else {
            NSLog(@"Subscribe request succeeded.");

            // Wait 5 seconds and then unsubscribe.
            [self performSelector:@selector(unsubscribe:) withObject:session afterDelay:5.0];
        }
    }];
}

-(void)unsubscribe:(const id)object {
    PTDiffusionSession *const session = object;

    NSLog(@"Unsubscribing...");
    [session.topics unsubscribeFromTopicSelectorExpression:_TopicSelectorExpression
                                         completionHandler:^(NSError * const error)
    {
        if (error) {
            NSLog(@"Unsubscribe request failed. Error: %@", error);
        } else {
            NSLog(@"Unsubscribe request succeeded.");

            // Wait 5 seconds and then subscribe.
            [self performSelector:@selector(subscribe:) withObject:session afterDelay:5.0];
        }
    }];
}

@end

@implementation SubscribeUnsubscribeExample (PTDiffusionTopicStreamDelegate)

-(void)diffusionStream:(PTDiffusionStream * const)stream
    didUpdateTopicPath:(NSString * const)topicPath
               content:(PTDiffusionContent * const)content
               context:(PTDiffusionUpdateContext * const)context {
    NSString *const string = [[NSString alloc] initWithData:content.data encoding:NSUTF8StringEncoding];
    NSLog(@"\t%@ = \"%@\"", topicPath, string);
}

-(void)     diffusionStream:(PTDiffusionStream * const)stream
    didSubscribeToTopicPath:(NSString * const)topicPath
                    details:(PTDiffusionTopicDetails * const)details {
    NSLog(@"Subscribed: \"%@\" (%@)", topicPath, details);
}

-(void)         diffusionStream:(PTDiffusionStream *const)stream
    didUnsubscribeFromTopicPath:(NSString *const)topicPath
                         reason:(const PTDiffusionTopicUnsubscriptionReason)reason {
    NSLog(@"Unsubscribed: \"%@\" [Reason: %@]", topicPath, PTDiffusionTopicUnsubscriptionReasonToString(reason));
}

@end
