//  Diffusion Client Library for iOS and OS X - Examples
//
//  Copyright (C) 2016 Push Technology Ltd.
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

#import "TopicUpdateSourceExample.h"

@import Diffusion;

@interface TopicUpdateSourceExample (PTDiffusionTopicUpdateSource) <PTDiffusionTopicUpdateSource>
@end

@implementation TopicUpdateSourceExample {
    PTDiffusionSession* _session;
}

-(void)startWithURL:(NSURL*)url {
    PTDiffusionCredentials *const credentials =
        [[PTDiffusionCredentials alloc] initWithPassword:@"password"];

    PTDiffusionSessionConfiguration *const sessionConfiguration =
        [[PTDiffusionSessionConfiguration alloc] initWithPrincipal:@"control"
                                                       credentials:credentials];

    NSLog(@"Connecting...");

    [PTDiffusionSession openWithURL:url
                      configuration:sessionConfiguration
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

        // Add topic.
        [self addTopicForSession:session];
    }];
}

static NSString *const _TopicPath = @"Example/Exclusively Updating";

-(void)addTopicForSession:(PTDiffusionSession *const)session {
    // Add a single value topic without an initial value.
    [session.topicControl addWithTopicPath:_TopicPath
                                      type:PTDiffusionTopicType_SingleValue
                                     value:nil
                         completionHandler:^(NSError * _Nullable error)
    {
        if (error) {
            NSLog(@"Failed to add topic. Error: %@", error);
        } else {
            NSLog(@"Topic created.");

            // Register as an exclusive update source.
            [self registerAsUpdateSourceForSession:session];
        }
    }];
}

-(void)registerAsUpdateSourceForSession:(PTDiffusionSession *const)session {
    [session.topicUpdateControl registerUpdateSource:self
                                        forTopicPath:_TopicPath
                                   completionHandler:^(PTDiffusionTopicTreeRegistration *const registration, NSError *const error)
    {
        if (registration) {
            NSLog(@"Registered as an update source.");
        } else {
            NSLog(@"Failed to register as an update source. Error: %@", error);
        }
    }];
}

-(void)updateTopicWithUpdater:(PTDiffusionTopicUpdater *const)updater
                        value:(const NSUInteger)value {
    // Prepare data to update topic with.
    NSString *const string =
        [NSString stringWithFormat:@"Update #%lu", (unsigned long)value];
    NSData *const data = [string dataUsingEncoding:NSUTF8StringEncoding];
    PTDiffusionContent *const content =
        [[PTDiffusionContent alloc] initWithData:data];

    // Update the topic.
    [updater updateWithTopicPath:_TopicPath
                           value:content
               completionHandler:^(NSError *const error)
    {
        if (error) {
            NSLog(@"Failed to update topic. Error: %@", error);
        } else {
            NSLog(@"Topic updated to \"%@\"", string);

            // Update topic after a short wait.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^
            {
                [self updateTopicWithUpdater:updater value:value + 1];
            });
        }
    }];
}

@end

@implementation TopicUpdateSourceExample (PTDiffusionTopicUpdateSource)

-(void)diffusionTopicTreeRegistration:(PTDiffusionTopicTreeRegistration *const)registration
                  isActiveWithUpdater:(PTDiffusionTopicUpdater *const)updater {
    NSLog(@"Registration is active.");

    // Start updating.
    [self updateTopicWithUpdater:updater value:1];
}

@end
