# syntax=docker/dockerfile:experimental
FROM spring-petclinic:2.4.0-SNAPSHOT as build

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

FROM spring-petclinic:2.4.0-SNAPSHOT

WORKDIR /workspace

ARG DEPENDENCY=/workspace
COPY --from=build ${DEPENDENCY}/libs /workspace/libs

ENTRYPOINT ["sh", "-c", "/layers/paketo-buildpacks_bellsoft-liberica/jre/bin/java -cp .:BOOT-INF/classes:BOOT-INF/lib/*:${EXT_LIBS}/* \
  org.springframework.samples.petclinic.PetClinicApplication ${0} ${@}"]
