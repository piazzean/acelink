# syntax=docker/dockerfile:1

# Ace Stream only ships an x86_64 engine. On linux/arm64 the x86_64 binary is run
# natively-hosted through box64 (a userspace x86_64 emulator with a dynamic recompiler),
# which is much faster than whole-VM emulation.

# Build box64 (only used on arm64, skipped via BuildKit on other platforms).
FROM ubuntu:focal AS box64
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive
ARG BOX64_VERSION=v0.4.4
RUN set -ex; \
    mkdir -p /out; \
    if [ "$TARGETARCH" = "arm64" ]; then \
        apt-get update; \
        apt-get install -yq --no-install-recommends ca-certificates git make gcc g++ python3 python3-pip; \
        python3 -m pip install --no-cache-dir cmake; \
        git clone --depth 1 --branch "$BOX64_VERSION" https://github.com/ptitSeb/box64 /box64; \
        cmake -S /box64 -B /box64/build -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=Release; \
        cmake --build /box64/build -j"$(nproc)"; \
        DESTDIR=/out cmake --install /box64/build; \
    fi

FROM ubuntu:focal

ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

ENV LC_ALL="C.UTF-8" \
    LANG="C.UTF-8" \
    DOWNLOAD_URL="https://download.acestream.media/linux/acestream_3.2.3_ubuntu_18.04_x86_64_py3.8.tar.gz" \
    CHECKSUM="bf45376f1f28aaff7d9849ff991bf34a6b9a65542460a2344a8826126c33727d"

COPY --from=box64 /out/ /

# Install system packages.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked\
    --mount=type=cache,target=/var/lib/apt,sharing=locked\
    --mount=type=tmpfs,target=/tmp\
    set -ex;\
    if [ "$TARGETARCH" = "arm64" ]; then\
        # The engine and its libraries are x86_64, so install amd64 packages next to arm64 ones.\
        dpkg --add-architecture amd64;\
        sed -i 's|^deb |deb [arch=arm64] |' /etc/apt/sources.list;\
        for suite in focal focal-updates focal-security; do\
            echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu $suite main universe" >> /etc/apt/sources.list;\
        done;\
        apt-get update;\
        apt-get install -yq --no-install-recommends ca-certificates libpython3.8:amd64 libc6:amd64 libstdc++6:amd64 python3.8 python3-pip wget;\
    else\
        apt-get update;\
        apt-get install -yq --no-install-recommends ca-certificates python3.8 libpython3.8 python3-pip wget;\
    fi;\
    mkdir -p /opt/acestream;\
    wget --no-verbose --output-document /opt/acestream/acestream.tgz $DOWNLOAD_URL;\
    echo "$CHECKSUM /opt/acestream/acestream.tgz" | sha256sum --check;\
    tar --extract --gzip --directory /opt/acestream --file /opt/acestream/acestream.tgz;\
    rm /opt/acestream/acestream.tgz;\
    if [ "$TARGETARCH" = "arm64" ]; then\
        # Fetch x86_64 wheels, since the engine's embedded python runs as x86_64.\
        python3.8 -m pip install --no-cache-dir --only-binary=:all: --platform manylinux2014_x86_64 --python-version 3.8 --implementation cp --target /usr/lib/python3/dist-packages -r /opt/acestream/requirements.txt;\
    else\
        python3 -m pip install -r /opt/acestream/requirements.txt;\
    fi;\
    /opt/acestream/start-engine --version;

# Overwrite disfunctional Ace Stream web player with a working videojs player,
# Access at http://127.0.0.1:6878/webui/player/<acestream id>
COPY player.html /opt/acestream/data/webui/html/player.html
COPY acestream.conf /opt/acestream/acestream.conf

# Prep dir serving m3u8 files.
RUN mkdir /acelink

EXPOSE 6878
EXPOSE 8621

ENTRYPOINT ["/opt/acestream/start-engine", "@/opt/acestream/acestream.conf"]
HEALTHCHECK CMD wget -q -t1 -O- 'http://127.0.0.1:6878/webui/api/service?method=get_version' | grep '"error": null'
