#!/bin/bash
DIR=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
python3 $DIR/check-required-templates.py "$@"
