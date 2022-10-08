#!/bin/bash

az policy definition create --name tagging-policy \
                            --display-name "Policy define" \
                            --description "This policy ensures all indexed resources." \
                            --rules tagging-policy.json --params tagging-policy-param.json \
                            --mode Indexed