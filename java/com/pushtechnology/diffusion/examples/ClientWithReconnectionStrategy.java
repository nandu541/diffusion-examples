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

import java.util.concurrent.TimeUnit;

import com.pushtechnology.diffusion.client.Diffusion;
import com.pushtechnology.diffusion.client.session.Session;
import com.pushtechnology.diffusion.client.session.Session.Listener;
import com.pushtechnology.diffusion.client.session.Session.State;
import com.pushtechnology.diffusion.client.session.reconnect.ReconnectionStrategy;


/**
 * This example class demonstrates the ability to set a custom {@link ReconnectionStrategy}
 * when creating sessions.
 *
 * @author Push Technology Limited
 * @since 5.5
 */
public class ClientWithReconnectionStrategy {

    /**
     * Constructor.
     */
    public ClientWithReconnectionStrategy() {

        // Set the maximum amount of time we'll try and reconnect for to 10 minutes.
        final long maximumTimeoutDuration = TimeUnit.MINUTES.toMillis(10);

        // Set the maximum interval between reconnect attempts to 60 seconds.
        final long maximumAttemptInterval = TimeUnit.SECONDS.toMillis(60);

        // Create a new reconnection strategy that applies an exponential backoff
        final ReconnectionStrategy reconnectionStrategy = new ReconnectionStrategy() {
            private int retries = 0;

            @Override
            public void apply(ReconnectionAttempt reconnection) {
                final long exponentialWaitTime =
                    Math.min((long) Math.pow(2,  retries++) * 100L, maximumAttemptInterval);

                try {
                    Thread.sleep(exponentialWaitTime);

                    retries++;

                    reconnection.start();
                }
                catch (InterruptedException e) {
                    reconnection.abort();
                }
            }
        };

        final Session session = Diffusion.sessions().reconnectionStrategy(reconnectionStrategy, maximumTimeoutDuration)
                                                    .open("ws://diffusion.example.com:80");
        session.addListener(new Listener() {
            @Override
            public void onSessionStateChanged(Session session, State oldState, State newState) {

                if (newState == State.RECOVERING_RECONNECT) {
                    // The session has been disconnected, and has entered recovery state. It is during this state that
                    // the reconnect strategy will be called
                }

                if (oldState == State.RECOVERING_RECONNECT) {
                    // The session has left recovery state. It may either be attempting to reconnect, or the attempt has
                    // been aborted; this will be reflected in the newState.
                }
            }
        });
    }
}