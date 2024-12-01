#!/bin/bash
name=noble-$(date +"%Y%m%d-%H%I%S")

./build.sh -t noble -n $name
