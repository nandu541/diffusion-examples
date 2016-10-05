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

#import "CounterSubscribeExample.h"

@import Diffusion;

@interface CounterSubscribeExample (PTDiffusionTopicStreamDelegate) <PTDiffusionTopicStreamDelegate>
@end

@implementation CounterSubscribeExample {
    PTDiffusionSession* _session;
}

-(void)start {
    NSLog(@"Connecting...");

    [PTDiffusionSession openWithURL:_url
                  completionHandler:^(PTDiffusionSession * const session, NSError * const error)
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

        NSLog(@"Subscribing...");
        [session.topics subscribeWithTopicSelectorExpression:@"foo/counter"
                                           completionHandler:^(NSError * const error)
        {
            if (error) {
                NSLog(@"Subscribe request failed. Error: %@", error);
            } else {
                NSLog(@"Subscribe request succeeded.");
            }
        }];
    }];
}

@end

@implementation CounterSubscribeExample (PTDiffusionTopicStreamDelegate)

-(void)diffusionStream:(PTDiffusionStream * const)stream
    didUpdateTopicPath:(NSString * const)topicPath
               content:(PTDiffusionContent * const)content
               context:(PTDiffusionUpdateContext * const)context {
    NSString *const string = [[NSString alloc] initWithData:content.data encoding:NSUTF8StringEncoding];
    NSLog(@"The value of %@ is: %@", topicPath, string);
}

@end
