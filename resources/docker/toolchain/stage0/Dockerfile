FROM alpine:edge

RUN apk update \
    && apk add --no-cache \
    ninja \
    make    \
    clang \
    clang-dev \
    bison \
    flex \
    # compiler-rt \               #
    # llvm-libunwind \
    # lld \
    gcc \
    libgcc
    curl \
    g++ \
    alpine-sdk \
    libatomic \
    libgcc \
    cmake \
    bash \
    git \
    linux-headers \
    zlib \
    zlib-dev \
    zstd \
    zstd-dev \
    tar \
    xz \
    python3

# RUN ln -sf /usr/bin/clang /usr/bin/cc \
#   && ln -sf /usr/bin/clang++ /usr/bin/c++ \
#   && ls -l /usr/bin/cc /usr/bin/c++ \
#   && cc --version \
#   && c++ --version
  # && update-alternatives --install /usr/bin/cc cc /usr/bin/clang 10\
  # && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 10\


RUN addgroup -S serene && \
    adduser -h /home/serene -S serene -G serene

USER serene:serene
ENV HOME=/home/serene
WORKDIR /home/serene/serene
