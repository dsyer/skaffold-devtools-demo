# syntax=docker/dockerfile:experimental
FROM runtime-demo:0.0.1-SNAPSHOT as build

WORKDIR /home/cnb

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
COPY target target

USER root
# Gnash, gnash...
RUN chown -R cnb:cnb /home/cnb
USER cnb

RUN --mount=type=cache,uid=1000,gid=1000,target=/home/cnb/.m2 src/build/extra-libs.sh

FROM runtime-demo:0.0.1-SNAPSHOT

WORKDIR /workspace

ARG DEPENDENCY=/workspace
COPY --from=build ${DEPENDENCY}/libs /workspace/libs

ENV MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=info,health,metrics,prometheus
ENTRYPOINT ["sh", "-c", "/layers/paketo-buildpacks_bellsoft-liberica/jre/bin/java -cp .:BOOT-INF/classes:BOOT-INF/lib/*:${EXT_LIBS}/*:${DEV_LIBS}/* \
  com.example.demo.DemoApplication ${0} ${@}"]
