#!/usr/bin/env bash
set -euo pipefail

IN_USER=badc0ded

docker network create --subnet=172.18.0.0/16 mynet123
cd run_env
docker run \
	-d \
	--net mynet123 \
	--ip 172.18.0.22 \
	-p 443:9999 \
	-v `pwd`/cert:/home/${IN_USER}/cert \
	-v `pwd`/notebooks:/home/${IN_USER}/notebooks \
	-v `pwd`/.jupyter:/home/${IN_USER}/.jupyter \
	jupyter:bionic \
	/bin/bash -c "source ~/.bashrc && conda activate colab && cd notebooks && jupyter notebook"
