FROM cloudfoundry/cflinuxfs2
MAINTAINER Stephen Levine <stephen.levine@gmail.com>

ENV \
  GO_VERSION=1.7 \
  DIEGO_VERSION=0.1482.0

RUN \
  curl -L "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz && \
  git -C /tmp clone --single-branch https://github.com/cloudfoundry/diego-release && \
  cd /tmp/diego-release && \
  git checkout "v${DIEGO_VERSION}" && \
  git submodule update --init --recursive \
    src/code.cloudfoundry.org/archiver \
    src/code.cloudfoundry.org/buildpackapplifecycle \
    src/code.cloudfoundry.org/bytefmt \
    src/code.cloudfoundry.org/cacheddownloader \
    src/github.com/cloudfoundry-incubator/candiedyaml \
    src/github.com/cloudfoundry/systemcerts && \
  export PATH=/usr/local/go/bin:$PATH && \
  export GOPATH=/tmp/diego-release && \
  go build -o /tmp/lifecycle/launcher code.cloudfoundry.org/buildpackapplifecycle/launcher && \
  go build -o /tmp/lifecycle/builder code.cloudfoundry.org/buildpackapplifecycle/builder && \
  rm -rf /tmp/diego-release /usr/local/go

USER vcap

ENV \
  CF_INSTANCE_ADDR= \
  CF_INSTANCE_PORT= \
  CF_INSTANCE_PORTS=[] \
  CF_INSTANCE_IP=0.0.0.0 \
  CF_STACK=cflinuxfs2 \
  HOME=/home/vcap \
  PATH=/usr/local/bin:/usr/bin:/bin \
  MEMORY_LIMIT=1024m \
  VCAP_SERVICES={}

ENV VCAP_APPLICATION '{ \
    "limits": {"fds": 16384, "mem": 1024, "disk": 1024}, \
    "application_name": "local", "name": "local", "space_name": "local-space", \
    "application_uris": ["localhost"], "uris": ["localhost"], \
    "application_id": "01d31c12-d066-495e-aca2-8d3403165360", \
    "application_version": "2b860df9-a0a1-474c-b02f-5985f53ea0bb", \
    "version": "2b860df9-a0a1-474c-b02f-5985f53ea0bb", \
    "space_id": "18300c1c-1aa4-4ae7-81e6-ae59c6cdbaf1" \
  }'

ENV BUILDPACKS \
  staticfile_buildpack:https://github.com/cloudfoundry/staticfile-buildpack/releases/download/v1.4.9/staticfile-buildpack-v1.4.9.zip \
  java_buildpack:https://github.com/cloudfoundry/java-buildpack/releases/download/v3.17/java-buildpack-v3.17.zip \
  ruby_buildpack:https://github.com/cloudfoundry/ruby-buildpack/releases/download/v1.6.41/ruby-buildpack-v1.6.41.zip \
  nodejs_buildpack:https://github.com/cloudfoundry/nodejs-buildpack/releases/download/v1.5.36/nodejs-buildpack-v1.5.36.zip \
  go_buildpack:https://github.com/cloudfoundry/go-buildpack/releases/download/v1.8.5/go-buildpack-v1.8.5.zip \
  python_buildpack:https://github.com/cloudfoundry/python-buildpack/releases/download/v1.5.19/python-buildpack-v1.5.19.zip \
  php_buildpack:https://github.com/cloudfoundry/php-buildpack/releases/download/v4.3.35/php-buildpack-v4.3.35.zip \
  dotnet_core_buildpack:https://github.com/cloudfoundry/dotnet-core-buildpack/releases/download/v1.0.20/dotnet-core-buildpack-v1.0.20.zip \
  binary_buildpack:https://github.com/cloudfoundry/binary-buildpack/releases/download/v1.0.13/binary-buildpack-v1.0.13.zip

RUN \
  mkdir -p /tmp/buildpacks && \
  for buildpack in $BUILDPACKS; do \
    name=$(echo "$buildpack" | cut -f1 -d:) && \
    url=$(echo "$buildpack" | cut -f2- -d:) && \
    curl -L -o /tmp/buildpack.zip "$url" && \
    unzip /tmp/buildpack.zip -d "/tmp/buildpacks/$(echo -n "$name" | md5sum | awk '{ print $1 }')" && \
    rm /tmp/buildpack.zip; \
  done

ONBUILD COPY . /tmp/app

ONBUILD USER root

ONBUILD RUN \
  mkdir -p /tmp/app /tmp/cache /home/vcap/tmp && \
  chown -R vcap:vcap /tmp/app /tmp/cache && \
  su vcap -p -c "cd /home/vcap && PATH=$PATH /tmp/lifecycle/builder -buildpackOrder $(echo "$BUILDPACKS" | tr -s ' ' '\n' | cut -f1 -d: | paste -sd,)" && \
  rm -rf /tmp/app /tmp/cache /home/vcap/tmp && \
  tar -C /home/vcap -xzf /tmp/droplet && \
  chown -R vcap:vcap /home/vcap && \
  rm -f /tmp/droplet /tmp/output-cache /tmp/result.json

ONBUILD USER vcap

ONBUILD ENV \
  CF_INSTANCE_INDEX=0 \
  CF_INSTANCE_ADDR=0.0.0.0:8080 \
  CF_INSTANCE_PORT=8080 \
  CF_INSTANCE_PORTS='[{"external":8080,"internal":8080}]' \
  CF_INSTANCE_GUID=999db41a-508b-46eb-74d8-6f9c06c006da \
  INSTANCE_GUID=999db41a-508b-46eb-74d8-6f9c06c006da \
  INSTANCE_INDEX=0 \
  PORT=8080 \
  TMPDIR=/home/vcap/tmp

ONBUILD ENV VCAP_APPLICATION '{ \
    "limits": {"fds": 16384, "mem": 1024, "disk": 1024}, \
    "application_name": "local", "name": "local", "space_name": "local-space", \
    "application_uris": ["localhost"], "uris": ["localhost"], \
    "application_id": "01d31c12-d066-495e-aca2-8d3403165360", \
    "application_version": "2b860df9-a0a1-474c-b02f-5985f53ea0bb", \
    "version": "2b860df9-a0a1-474c-b02f-5985f53ea0bb", \
    "space_id": "18300c1c-1aa4-4ae7-81e6-ae59c6cdbaf1", \
    "instance_id": "999db41a-508b-46eb-74d8-6f9c06c006da", \
    "host": "0.0.0.0", "instance_index": 0, "port": 8080 \
  }'

ONBUILD EXPOSE 8080

ONBUILD CMD cd /home/vcap/app && /tmp/lifecycle/launcher /home/vcap/app "$(jq -r .start_command /home/vcap/staging_info.yml)" ''
