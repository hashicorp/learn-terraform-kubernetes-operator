#!/bin/sh
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -e

export AWS_ACCESS_KEY_ID=$(cat /tmp/secrets/AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/secrets/AWS_SECRET_ACCESS_KEY)
export SQS_URL=$(eval echo $QUEUE_URL | sed 's/"//g')

echo $SQS_URL

echo "sending a message to queue $SQS_URL"
aws sqs send-message --queue-url $SQS_URL --message-body "hello world!" --message-group-id "greetings" --message-deduplication-id "world"

echo "reading a message from queue $SQS_URL"
aws sqs receive-message --queue-url $SQS_URL