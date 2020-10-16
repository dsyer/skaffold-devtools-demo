#!/bin/bash -x

echo "Locating thin launcher"

ls -ld ~/.m2
ls -l ~/.m2

BASE=`dirname $0`/../..
TARGET=${BASE}/target

export JAVA_HOME=${JAVA_HOME:-/layers/paketo-buildpacks_bellsoft-liberica/jre/}
if ! which java 2> /dev/null; then
  export PATH=$PATH:${JAVA_HOME}/bin
fi

if [ -z ${THIN_VERSION} ]; then THIN_VERSION=1.0.25.RELEASE; fi
if [ -z ${JAR_FILE} ]; then JAR_FILE=${TARGET}/runtime-demo-0.0.1-SNAPSHOT.jar; fi
THIN_JAR=~/.m2/repository/org/springframework/boot/experimental/spring-boot-thin-launcher/${THIN_VERSION}/spring-boot-thin-launcher-${THIN_VERSION}-exec.jar

if ! [ -e ${THIN_JAR} ]; then
  $BASE/mvnw dependency:get -Dartifact=org.springframework.boot.experimental:spring-boot-thin-launcher:${THIN_VERSION}:jar:exec -Dtransitive=false
fi

echo "Installing additional jars"

CPPARENT=`java -Dthin.trace=true -jar ${THIN_JAR} --thin.archive=${JAR_FILE} --thin.classpath`

function install {
  
  local profile=${1:-k8s}
  echo Calculating classpath diffs for profile=${profile}
  
  CPCHILD=`java -Dthin.trace=true -jar ${THIN_JAR} --thin.archive=${JAR_FILE} --thin.classpath --thin.parent=${JAR_FILE} --thin.profile=${profile}`

  mkdir -p /workspace/libs/${profile}
  for f in `echo ${CPCHILD#${CPPARENT}*} | tr ':' ' '`; do
    cp $f /workspace/libs/${profile};
  done

}

install k8s
install dev