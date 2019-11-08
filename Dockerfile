ARG JDK_VERSION=8
FROM openjdk:${JDK_VERSION}-alpine
ARG SCALA_VERSION
ARG SBT_VERSION
ARG COURSIER_VERSION

RUN : "${SCALA_VERSION:?SCALA_VERSION needs to be set and non-empty.}" \
  : "${SBT_VERSION:?SBT_VERSION needs to be set and non-empty.}" \
  : "${COURSIER_VERSION:?COURSIER_VERSION needs to be set and non-empty.}"

ENV SBT_HOME /usr/bin/sbt
ENV PATH ${PATH}:${SBT_HOME}/bin

RUN apk add bash=4.4.19-r1 --no-cache
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apk add --no-cache --virtual=build-dependencies wget=1.20.3-r0 openssl=1.1.1d-r0 && mkdir -p ${SBT_HOME} && \
  wget -qO- "https://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz" | tar xz -C /root/ && \
  echo "export PATH=~/scala-$SCALA_VERSION/bin:$PATH" >> /root/.bashrc && \
  wget -qO- --no-check-certificate "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" | tar xz -C $SBT_HOME --strip-components=1 && \
  mkdir -p /root/.sbt/${SBT_VERSION%.*}/plugins  && \
  echo "addSbtPlugin(\"io.get-coursier\" % \"sbt-coursier\" % \"${COURSIER_VERSION}\")" >> /root/.sbt/${SBT_VERSION%.*}/plugins/plugins.sbt && \
  echo 'classpathTypes += maven-plugin' >> /root/.sbt/${SBT_VERSION%.*}/sbt-coursier.sbt && \
  mkdir project && \
  echo "scalaVersion := \"${SCALA_VERSION}\"" > build.sbt && \
  echo "sbt.version=${SBT_VERSION}" > project/build.properties && \
  sbt update && \
  rm -r project && rm build.sbt && \
  apk del build-dependencies

WORKDIR /root
