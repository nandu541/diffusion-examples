/**
 * Copyright © 2014, 2016 Push Technology Ltd.
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
 */

using System;
using System.Threading;
using System.Threading.Tasks;
using PushTechnology.ClientInterface.Client.Callbacks;
using PushTechnology.ClientInterface.Client.Factories;
using PushTechnology.ClientInterface.Client.Features.Control.Topics;
using PushTechnology.ClientInterface.Client.Topics;

namespace GettingStarted {
    /// <summary>
    /// A client that publishes an incrementing count to the topic "foo/counter".
    /// </summary>
    class PublishingClient {
        static void Main( string[] args ) {
            // Connect using a principal with 'modify_topic' and 'update_topic' permissions
            var session = Diffusion.Sessions.Principal( "principal" ).Password( "password" ).Open( "ws://host:80" );

            // Get the TopicControl and TopicUpdateControl features
            var topicControl = session.GetTopicControlFeature();

            var updateControl = session.GetTopicUpdateControlFeature();

            var addCallback = new AddCallback();

            // Create a single-value topic 'foo/counter'
            topicControl.AddTopic( "foo/counter", TopicType.SINGLE_VALUE, addCallback );

            // Wait for the OnTopicAdded callback, or a failure
            if ( !addCallback.Wait( TimeSpan.FromSeconds( 5 ) ) ) {
                Console.WriteLine( "Callback not received within timeout." );
                return;
            } else if ( addCallback.Error != null ) {
                Console.WriteLine( "Error : {0}", addCallback.Error.ToString() );
                return;
            }

            var updateCallback = new UpdateCallback();
            // Update the topic for 16 minutes
            for ( var i = 0; i < 1000; ++i ) {
                // Use the non-exclusive updater to update the topic without locking it
                updateControl.Updater.Update( "foo/counter", i.ToString(), updateCallback );

                Thread.Sleep( 1000 );
            }
        }

        private class AddCallback : ITopicControlAddCallback {
            private readonly AutoResetEvent resetEvent = new AutoResetEvent( false );

            /// <summary>
            /// Any error from this AddCallback will be stored here.
            /// </summary>
            public Exception Error {
                get;
                private set;
            }

            public AddCallback() {
                Error = null;
            }

            /// <summary>
            /// This is called to notify that a call context was closed prematurely, typically due to a timeout or the
            /// session being closed. No further calls will be made for the context.
            /// </summary>
            public void OnDiscard() {
                Error = new Exception( "This context was closed prematurely." );
                resetEvent.Set();
            }

            /// <summary>
            /// This is called to notify that the topic has been added.
            /// </summary>
            /// <param name="topicPath">The full path of the topic that was added.</param>
            public void OnTopicAdded( string topicPath ) {
                resetEvent.Set();
            }

            /// <summary>
            /// This is called to notify that an attempt to add a topic has failed.
            /// </summary>
            /// <param name="topicPath">The topic path as supplied to the add request.</param>
            /// <param name="reason">The reason for failure.</param>
            public void OnTopicAddFailed( string topicPath, TopicAddFailReason reason ) {
                Error = new Exception( string.Format( "Failed to add topic {0} : '{1}", topicPath, reason ) );
                resetEvent.Set();
            }

            public bool Wait( TimeSpan timeout ) {
                return resetEvent.WaitOne( timeout );
            }
        }

        private class UpdateCallback : ITopicUpdaterUpdateCallback {
            /// <summary>
            /// Notification of a contextual error related to this callback. This is analogous to an exception being
            /// raised. Situations in which <code>OnError</code> is called include the session being closed, a
            /// communication timeout, or a problem with the provided parameters. No further calls will be made to this
            /// callback.
            /// </summary>
            /// <param name="errorReason">errorReason a value representing the error; this can be one of
            /// constants defined in <see cref="T:PushTechnology.ClientInterface.Client.Callbacks.ErrorReason"/>, or a
            /// feature-specific reason.</param>
            public void OnError( ErrorReason errorReason ) {
                // Handle any errors here
            }

            /// <summary>
            /// Indicates a successful update.
            /// </summary>
            public void OnSuccess() {
                // Handle the success here
            }
        }
    }
}
