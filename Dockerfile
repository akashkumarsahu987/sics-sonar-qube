FROM amazoncorretto:17

ARG NODEJS_VERSION=12.18.3

# ---------------------
# Install prerequisites
# ---------------------
RUN yum install -y wget tar gz xz yum-utils device-mapper-persistent-data lvm2

# -----------
# Install GIT
# -----------
RUN yum install -y git

# --------------
# Install Docker
# --------------
RUN amazon-linux-extras enable docker
RUN yum install -y docker
RUN usermod -aG docker root
RUN newgrp docker

# ---------------------
# Install Node.js + npm
#----------------------
ENV NODEJS_LIB_DIR /usr/local/lib/nodejs

RUN mkdir -p ${NODEJS_LIB_DIR}
RUN wget -nv -q https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.xz
RUN tar -xJf node-v${NODEJS_VERSION}-linux-x64.tar.xz -C ${NODEJS_LIB_DIR}
RUN rm node-v${NODEJS_VERSION}-linux-x64.tar.xz
RUN ln -s ${NODEJS_LIB_DIR}/node-v${NODEJS_VERSION}-linux-x64/bin/npx /usr/bin/npx
RUN ln -s ${NODEJS_LIB_DIR}/node-v${NODEJS_VERSION}-linux-x64/bin/npm /usr/bin/npm
RUN ln -s ${NODEJS_LIB_DIR}/node-v${NODEJS_VERSION}-linux-x64/bin/node /usr/bin/node
RUN npm install github-markdown -g

# --------------------
# Install Apache Maven
# --------------------
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_OPTS="-Xss2048k -Xmx2048m"

RUN yum install -y which

RUN MAVEN_VERSION=$(curl -s https://downloads.apache.org/maven/maven-3/ 2>/dev/null | grep href | sed -rn 's/.*href="([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)\/">.*/\1/p' | sort -r | head -n 1) && \
  mkdir -p $MAVEN_HOME ${MAVEN_HOME}/ref && \
  wget -nv -q https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  tar --extract --file apache-maven-${MAVEN_VERSION}-bin.tar.gz --directory "$MAVEN_HOME" --strip-components 1 --no-same-owner && \
  rm apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
  ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn
