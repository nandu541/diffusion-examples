/*******************************************************************************
 * Copyright (C) 2014, 2015 Push Technology Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *******************************************************************************/
package com.pushtechnology.diffusion.examples;

import com.pushtechnology.diffusion.client.Diffusion;
import com.pushtechnology.diffusion.client.features.RegisteredHandler;
import com.pushtechnology.diffusion.client.features.control.topics.TopicAddFailReason;
import com.pushtechnology.diffusion.client.features.control.topics.TopicControl;
import com.pushtechnology.diffusion.client.features.control.topics.TopicControl.MissingTopicHandler;
import com.pushtechnology.diffusion.client.features.control.topics.TopicControl.MissingTopicNotification;
import com.pushtechnology.diffusion.client.session.Session;
import com.pushtechnology.diffusion.client.topics.details.TopicDetails;
import com.pushtechnology.diffusion.client.topics.details.TopicType;

/**
 * An example of registering a missing topic notification handler and processing
 * notifications using a control client.
 *
 * @author Push Technology Limited
 */
public final class ControlClientHandlingMissingTopicNotification {

    // UCI features
    private final Session session;
    private final TopicControl topicControl;
    private final TopicDetails details;

    /**
     * Constructor.
     */
    public ControlClientHandlingMissingTopicNotification() {
        // Create a session
        session = Diffusion.sessions().password("password").principal("admin").open("ws://diffusion.example.com:8080");

        topicControl = session.feature(TopicControl.class);

        // Registers a missing topic notification on a topic path
        topicControl.addMissingTopicHandler("A", new MissingTopicNotificationHandler());

        // For details that may be reused many times it is far more efficient to
        // create just once - this creates a default string type details.
        details = topicControl.newDetails(TopicType.SINGLE_VALUE);

    }

    // Private class that implements MissingTopicHandler interface
    private final class MissingTopicNotificationHandler implements
            MissingTopicHandler {
        /**
         * @param topicPath
         *            - the path that the handler is active for
         * @param registeredHandler
         *            - allows the handler to be closed
         */
        @Override
        public void onActive(String topicPath, RegisteredHandler registeredHandler) {
        }

        /**
         * @param topicPath
         *            - the branch of the topic tree for which the handler was
         *            registered
         */
        @Override
        public void onClose(String topicPath) {
        }

        /**
         * @param notification
         *            - the missing topic details
         */
        @Override
        public void onMissingTopic(MissingTopicNotification notification) {
            // Create a topic and do process() in the callback
            topicControl.addTopic(notification.getTopicPath(), details, new AddTopicCallback(notification));
        }
    }

    private final class AddTopicCallback implements TopicControl.AddCallback {
        private final MissingTopicNotification notification;

        AddTopicCallback(MissingTopicNotification notification) {
            this.notification = notification;
        }

        @Override
        public void onDiscard() {
        }

        /**
         * @param topicPath
         *            - the topic path as supplied to the add request
         * @param reason
         *            - the reason for failure
         */
        @Override
        public void onTopicAddFailed(String topicPath, TopicAddFailReason reason) {
            // Cancel the notification because the server have failed to
            notification.cancel();
        }

        /**
         * @param topicPath
         *            - the full path of the topic that was added
         */
        @Override
        public void onTopicAdded(String topicPath) {
            // Proceed the notification
            notification.proceed();
        }

    }

}
