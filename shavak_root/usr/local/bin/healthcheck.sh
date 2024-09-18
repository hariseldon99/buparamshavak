#!/bin/bash
# Update status of server to healthchecks.io
# using curl (10 second timeout, retry up to 5 times):
curl -m 10 --retry 5 https://hc-ping.com/6995f912-0fb8-4288-8384-adf73edbc47c
