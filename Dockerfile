FROM ubuntu:20.04

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
RUN apt-get update && apt-get install -y --no-install-recommends tzdata curl ca-certificates fontconfig locales && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen en_US.UTF-8 && rm -rf /var/lib/apt/lists/*
ENV JAVA_VERSION=jdk8u292-b10
RUN set -eux; ARCH="$(dpkg --print-architecture)"; case "${ARCH}" in aarch64|arm64) ESUM='a29edaf66221f7a51353d3f28e1ecf4221268848260417bc562d797e514082a8'; BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_aarch64_linux_hotspot_8u292b10.tar.gz'; ;; armhf|armv7l) ESUM='0de107b7df38314c1daab78571383b8b39fdc506790aaef5d870b3e70048881b'; BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_arm_linux_hotspot_8u292b10.tar.gz'; ;; ppc64el|ppc64le) ESUM='7ecf00e57033296fd23201477a64dc13a1356b16a635907e104d079ddb544e4b'; BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_ppc64le_linux_hotspot_8u292b10.tar.gz'; ;; s390x) ESUM='276a431c79b7e94bc1b1b4fd88523383ae2d635ea67114dfc8a6174267f8fb2c'; BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_s390x_linux_hotspot_8u292b10.tar.gz'; LIBFFI_SUM='05e456a2e8ad9f20db846ccb96c483235c3243e27025c3e8e8e358411fd48be9'; LIBFFI_URL='http://launchpadlibrarian.net/354371408/libffi6_3.2.1-8_s390x.deb'; curl -LfsSo /tmp/libffi6.deb ${LIBFFI_URL}; echo "${LIBFFI_SUM} /tmp/libffi6.deb" | sha256sum -c -; apt-get install -y --no-install-recommends /tmp/libffi6.deb; rm -rf /tmp/libffi6.deb; ;; amd64|x86_64) ESUM='0949505fcf42a1765558048451bb2a22e84b3635b1a31dd6191780eeccaa4ada'; BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u292-b10/OpenJDK8U-jdk_x64_linux_hotspot_8u292b10.tar.gz'; ;; *) echo "Unsupported arch: ${ARCH}"; exit 1; ;; esac; curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; mkdir -p /opt/java/openjdk; cd /opt/java/openjdk; tar -xf /tmp/openjdk.tar.gz --strip-components=1; rm -rf /tmp/openjdk.tar.gz;
ENV JAVA_HOME=/opt/java/openjdk PATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install --yes --no-install-recommends python3 python3-pip && pip3 install --upgrade pip && pip3 install awscli && rm -rf /var/cache/apk/*
RUN aws --version

RUN apt-get update && apt-get install --yes --no-install-recommends amazon-ecr-credential-helper && rm -rf /var/cache/apk/*

ENV GRADLE_HOME=/opt/gradle
RUN set -o errexit -o nounset && echo "Adding gradle user and group" && groupadd --system --gid 1000 gradle && useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle && mkdir /home/gradle/.gradle && chown --recursive gradle:gradle /home/gradle && echo "Symlinking root Gradle cache to gradle Gradle cache" && ln -s /home/gradle/.gradle /root/.gradle
WORKDIR /home/gradle
RUN apt-get update && apt-get install --yes --no-install-recommends fontconfig unzip wget bzr git git-lfs mercurial openssh-client subversion && rm -rf /var/lib/apt/lists/*
ENV GRADLE_VERSION=6.9
ARG GRADLE_DOWNLOAD_SHA256=765442b8069c6bee2ea70713861c027587591c6b1df2c857a23361512560894e
RUN set -o errexit -o nounset && echo "Downloading Gradle" && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" && echo "Checking download hash" && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - && echo "Installing Gradle" && unzip gradle.zip && rm gradle.zip && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle && echo "Testing Gradle installation" && gradle --version

CMD ["gradle"]
