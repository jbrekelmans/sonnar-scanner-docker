ARG BASE_IMAGE='alpine:3.10'
ARG JAVA_BUILDER_IMAGE='adoptopenjdk/openjdk11:jdk-11.0.5_10-alpine'
FROM ${BASE_IMAGE} AS sonar-scanner-cli-builder
ARG SONAR_SCANNER_CLI_VERSION='4.2.0.1873'
ARG SONAR_SCANNER_CLI_SHA256='44a5d985fc3bc10a8d4217160d2117289b7fe582acd410652b4bf59924593ce6'
RUN apk add --no-cache curl unzip
# Download and unzip sonar-scanner-cli
ENV SONAR_SCANNER_CLI_VERSION=$SONAR_SCANNER_CLI_VERSION
ENV SONAR_SCANNER_CLI_SHA256=$SONAR_SCANNER_CLI_SHA256
RUN cd /opt && \
    curl --fail -L --output sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-"$SONAR_SCANNER_CLI_VERSION"-linux.zip && \
    # NOTE: the double space in sha256sum stdin is required
    echo "$SONAR_SCANNER_CLI_SHA256  sonar-scanner.zip" | sha256sum -c - && \
    unzip -q sonar-scanner.zip && \
    rm -rf sonar-scanner.zip && \
    mv sonar-scanner* sonar-scanner

# sonar-scanner-cli can be run directly from debian:stretch image.
# We instead run it from alpine to reduce the final image size by ~30MB compared to the debian:buster-slim base image, but thiss requires we
# install glibc on alpine.
FROM ${BASE_IMAGE}
# sonnar-scanner-cli's JRE requires glibc, so install it.
# sonnar-scanner-cli 4.2.0.1873 comes with an embedded Java 11 JRE.
# So we can look to AdoptOpenJDK for inspiration: https://github.com/AdoptOpenJDK/openjdk-docker/blob/22b1df56dc2e7939747f0a3759799bb322b5a8ac/11/jre/alpine/Dockerfile.hotspot.releases.full#L24
# on how to install glibc.
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'
RUN apk --update add --virtual .build-deps --no-cache curl binutils && \
    GLIBC_VER="2.29-r0" && \
    ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz" && \
    GCC_LIBS_SHA256="91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08" && \
    ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" && \
    ZLIB_SHA256="17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5" && \
    { \
        echo '-----BEGIN PUBLIC KEY-----' && \
        echo 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m' && \
        echo 'y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu' && \
        echo 'tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp' && \
        echo 'm2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY' && \
        echo 'KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc' && \
        echo 'Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m' && \
        echo '1QIDAQAB' && \
        echo '-----END PUBLIC KEY-----'; \
    } > /etc/apk/keys/sgerrand.rsa.pub && \
    TMP_DIR=$(mktemp -d) && \
    curl --fail -L "${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}".apk > "${TMP_DIR}/glibc-${GLIBC_VER}".apk && \
    apk add "${TMP_DIR}/glibc-${GLIBC_VER}".apk && \
    curl --fail -L "${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}".apk > "${TMP_DIR}/glibc-bin-${GLIBC_VER}".apk && \
    apk add --no-cache "${TMP_DIR}/glibc-bin-${GLIBC_VER}".apk && \
    curl --fail -L "${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}".apk > "${TMP_DIR}/glibc-i18n-${GLIBC_VER}".apk && \
    apk add --no-cache "${TMP_DIR}/glibc-i18n-${GLIBC_VER}".apk && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    curl --fail -L "${GCC_LIBS_URL}" -o "${TMP_DIR}"/gcc-libs.tar.xz && \
    echo "${GCC_LIBS_SHA256} *${TMP_DIR}/gcc-libs.tar.xz" | sha256sum -c - && \
    mkdir "${TMP_DIR}"/gcc && \
    tar -xf "${TMP_DIR}"/gcc-libs.tar.xz -C "${TMP_DIR}"/gcc && \
    mv "${TMP_DIR}"/gcc/usr/lib/libgcc* "${TMP_DIR}"/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib && \
    strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* && \
    curl --fail -L "${ZLIB_URL}" -o "${TMP_DIR}"/libz.tar.xz && \
    echo "${ZLIB_SHA256} *${TMP_DIR}/libz.tar.xz" | sha256sum -c - && \
    mkdir "${TMP_DIR}"/libz && \
    tar -xf "${TMP_DIR}/libz.tar.xz" -C "${TMP_DIR}"/libz && \
    mv "${TMP_DIR}"/libz/usr/lib/libz.so* /usr/glibc-compat/lib && \
    apk del .build-deps && \
    rm -rf "$TMP_DIR" /var/cache/apk/* /etc/apk/keys/sgerrand.rsa.pub

COPY --from=sonar-scanner-cli-builder /opt/sonar-scanner /opt/sonar-scanner
ENV PATH=/opt/sonar-scanner/bin:/opt/sonar-scanner/jre/bin:$PATH
ENTRYPOINT ["sonar-scanner"]

# Set SONAR_URL to non-zero to warmup the plugins cache, this could add ~100MB.
ARG SONAR_URL=
RUN [ -z $SONAR_URL ] || { \
        cd /root && sonar-scanner -Dsonar.host.url="$SONAR_URL" -X; \
        exit 0; \
    }
