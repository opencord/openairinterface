#
# Copyright 2019-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:16.04 AS base-builder
RUN apt-get update && apt-get install -y \
    sudo \
    linux-headers-`uname -r` \
    vim-common \
    git \
    build-essential \
    cmake \
 && rm -rf /var/lib/apt/lists/*
RUN git clone https://gitlab.eurecom.fr/oai/openairinterface5g/ /openairinterface5g
WORKDIR /openairinterface5g
ENV USER=root
RUN git checkout -f v1.0.0 && \
    /bin/bash -c "source oaienv" && \
    cd cmake_targets && \
    ./build_oai -I

FROM base-builder AS enb-builder
WORKDIR /openairinterface5g
ENV USER=root
RUN /bin/bash -c "source oaienv" && \
    cd cmake_targets && \
    ./build_oai --eNB -t ETHERNET -c

FROM ubuntu:16.04 AS lte-softmodem
RUN apt-get update && apt-get install -y \
    libssl1.0.0 \
    libnettle6 \
    libsctp1 \
    libforms2 \
    libprotobuf-c1 \
    libyaml-0-2 \
    libconfig9 \
    dnsutils \
    iproute2 \
    iputils-ping \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /openairinterface5g/cmake_targets
COPY --from=enb-builder /openairinterface5g/cmake_targets/ .

FROM base-builder AS ue-builder
WORKDIR /openairinterface5g
ENV USER=root
RUN /bin/bash -c "source oaienv" && \
    cd cmake_targets && \
    ./build_oai --UE -t ETHERNET -c

FROM ubuntu:16.04 AS lte-uesoftmodem
RUN apt-get update && apt-get install -y \
    libssl1.0.0 \
    libnettle6 \
    libsctp1 \
    libforms2 \
    libconfig9 \
    libblas3 \
    liblapacke \
    sudo \
    dnsutils \
    iproute2 \
    iputils-ping \
    net-tools \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /openairinterface5g/cmake_targets
COPY --from=ue-builder /openairinterface5g/cmake_targets .
COPY --from=ue-builder /openairinterface5g/targets/bin/nvram .
COPY --from=ue-builder /openairinterface5g/targets/bin/usim .
COPY --from=ue-builder /openairinterface5g/targets ../targets
