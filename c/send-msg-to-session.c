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
 *
 * This example is written in C99. Please use an appropriate C99 capable compiler
 *
 * @author Push Technology Limited
 * @since 5.6
 */

/*
 * This example shows how a message can be sent to another client via
 * a topic endpoint. The session ID of the target client must be
 * known.
 *
 * See msg-listener.c for an example of how to receive these messages
 * in a client.
 */

#include <stdio.h>
#include <unistd.h>

#include <apr.h>
#include <apr_thread_mutex.h>
#include <apr_thread_cond.h>

#include "diffusion.h"
#include "args.h"

apr_pool_t *pool = NULL;
apr_thread_mutex_t *mutex = NULL;
apr_thread_cond_t *cond = NULL;

ARG_OPTS_T arg_opts[] = {
        ARG_OPTS_HELP,
        {'u', "url", "Diffusion server URL", ARG_OPTIONAL, ARG_HAS_VALUE, "ws://localhost:8080"},
        {'p', "principal", "Principal (username) for the connection", ARG_OPTIONAL, ARG_HAS_VALUE, NULL},
        {'c', "credentials", "Credentials (password) for the connection", ARG_OPTIONAL, ARG_HAS_VALUE, NULL},
        {'t', "topic", "Topic name", ARG_REQUIRED, ARG_HAS_VALUE, "echo"},
        {'s', "session_id", "Session id", ARG_REQUIRED, ARG_HAS_VALUE, NULL},
        {'d', "data", "Data to send", ARG_REQUIRED, ARG_HAS_VALUE, NULL},
        END_OF_ARG_OPTS
};

/*
 * Callback invoked when/if a message is published on the topic that the
 * client is writing to.
 */
static int
on_send(SESSION_T *session, void *context)
{
        printf("on_send() successful. Context=\"%s\".\n", (char *)context);

        /*
         * Allow main thread to continue.
         */
        apr_thread_mutex_lock(mutex);
        apr_thread_cond_broadcast(cond);
        apr_thread_mutex_unlock(mutex);

        return HANDLER_SUCCESS;
}

int
main(int argc, char **argv)
{
        /*
         * Standard command-line parsing.
         */
        HASH_T *options = parse_cmdline(argc, argv, arg_opts);
        if(options == NULL || hash_get(options, "help") != NULL) {
                show_usage(argc, argv, arg_opts);
                return EXIT_FAILURE;
        }

        char *url = hash_get(options, "url");

        const char *principal = hash_get(options, "principal");
        CREDENTIALS_T *credentials = NULL;

        const char *password = hash_get(options, "credentials");
        if(password != NULL) {
                credentials = credentials_create_password(password);
        }

        char *topic = hash_get(options, "topic");
        char *session_id_str = hash_get(options, "session_id");

        /*
         * Setup for condition variable.
         */
        apr_initialize();
        apr_pool_create(&pool, NULL);
        apr_thread_mutex_create(&mutex, APR_THREAD_MUTEX_UNNESTED, pool);
        apr_thread_cond_create(&cond, pool);

        /*
         * Create a session with Diffusion.
         */
        SESSION_T *session = NULL;
        DIFFUSION_ERROR_T error = { 0 };
        session = session_create(url, principal, credentials, NULL, NULL, &error);
        if(session == NULL) {
                fprintf(stderr, "TEST: Failed to create session\n");
                fprintf(stderr, "ERR : %s\n", error.message);
                return EXIT_FAILURE;
        }

        /*
         * Create a payload.
         */
        char *data = hash_get(options, "data");
        BUF_T *payload = buf_create();
        buf_write_bytes(payload, data, strlen(data));
        CONTENT_T *content = content_create(CONTENT_ENCODING_NONE, payload);
        buf_free(payload);

        /*
         * Build up some headers to send with the message.
         */
        LIST_T *headers = list_create();
        list_append_last(headers, "apple");
        list_append_last(headers, "train");

        /*
         * Parameters for send_msg_to_session() call.
         */
        SESSION_ID_T *session_id = session_id_create_from_string(session_id_str);

        SEND_MSG_TO_SESSION_PARAMS_T params = {
                .topic_path = topic,
                .session_id = *session_id,
                .content = *content,
                .options.headers = headers,
                .options.priority = CLIENT_SEND_PRIORITY_NORMAL,
                .on_send = on_send,
                .context = "FOO"
        };

        /*
         * Send the message and wait for the callback to acknowledge
         * delivery.
         */
        apr_thread_mutex_lock(mutex);
        send_msg_to_session(session, params);
        apr_thread_cond_wait(cond, mutex);
        apr_thread_mutex_unlock(mutex);

        /*
         * Politely close the client connection and clean up.
         */
        session_id_free(session_id);
        session_close(session, NULL);
        session_free(session);

        apr_thread_mutex_destroy(mutex);
        apr_thread_cond_destroy(cond);
        apr_pool_destroy(pool);
        apr_terminate();

        return EXIT_SUCCESS;
}
