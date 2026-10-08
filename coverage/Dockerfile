# The libraries that read the registry's formats, built so that every line a run reaches is counted, and the
# programs and tools that `fanbase evaluate --coverage` needs to count them. CI uses this image rather than
# compiling anything: building it takes a while (about ten minutes), running it does not.
#
#   docker build -t fanbase-coverage coverage/
#   docker run --rm -v "$PWD":/registry -w /registry fanbase-coverage \
#       fanbase evaluate png --coverage --curve 1,10,100,1000 -n 1000 --hide-crashes
#
# What is in it is pinned (see build-libs.sh); the base image is not.
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential cmake ninja-build pkg-config git ca-certificates curl \
        zlib1g-dev libjpeg-dev liblzma-dev libzstd-dev imagemagick webp age \
    && rm -rf /var/lib/apt/lists/*

# `fanbase` is the one to evaluate with; pass FANBASE=/path/to/a.whl to build with a version that is not released.
ARG FANBASE="fanbase>=0.5"
RUN pip install --no-cache-dir fandango-fuzzer Pillow ${FANBASE:+"$FANBASE"}

# the libraries, from pinned sources, built with counting; the slow part, so first
COPY build-libs.sh /opt/cov/build-libs.sh
RUN /opt/cov/build-libs.sh

# the programs that read a file with them, and the tools that clear and read the counters
COPY libs.json /opt/cov/libs.json
COPY harness /opt/cov/harness
COPY build-harness.sh /opt/cov/build-harness.sh
RUN /opt/cov/build-harness.sh
COPY bin /opt/cov/bin
COPY make-seeds.sh /opt/cov/make-seeds.sh
RUN chmod +x /opt/cov/bin/* && /opt/cov/make-seeds.sh

ENV PATH=/opt/cov/bin:$PATH
WORKDIR /registry
