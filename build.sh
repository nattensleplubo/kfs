#!/bin/bash
docker run -v $(pwd):/root/env myos-buildenv make "$@"