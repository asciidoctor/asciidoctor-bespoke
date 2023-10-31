#!/usr/bin/env bats

: ${ASCIIDOC_VERSION='1.5.4'}
: ${DOCKER_IMAGE='asciidoctor-bespokejs:latest'}
: ${DOCKER_HOST_IP:=$(docker-machine ip)}
: ${CONTAINER_TEST_NAME:='asciidoctor-test'}
: ${TEST_PROJECT=$(pwd)/starter}

### Load Utility functions
clean_testing_docker_containers() {
  docker kill "${CONTAINER_TEST_NAME}" || true
  docker rm -v "${CONTAINER_TEST_NAME}" || true
}
run_interactive_docker_command() {
  docker run --rm -ti --entrypoint sh "${DOCKER_IMAGE}" -c "${*}"
}

### The tests !!
@test "I can build the docker image" {
  run docker build -t "${DOCKER_IMAGE}" ./
  [ ${status} -eq 0 ]
}

@test "We have a ruby binary installed, in the PATH" {
  run run_interactive_docker_command ruby -v
  [ ${status} -eq 0 ]
}

@test "Ruby bundler is installed and in the PATH" {
  run run_interactive_docker_command bundle -v
  [ ${status} -eq 0 ]
}

@test "The image contains asciidoc in ${ASCIIDOC_VERSION}" {
  run run_interactive_docker_command bundle exec asciidoctor --version
  [ ${status} -eq 0 ]
  echo ${output} | grep ${ASCIIDOC_VERSION} # Will fail if no line found by grep
}

@test "asciidoctor is installed system-wide" {
  run run_interactive_docker_command "cd /tmp && bundle exec asciidoctor --version"
  [ ${status} -eq 0 ]
}

@test "We have NPM (and NodeJS by transitivity) installed, in the PATH" {
  run run_interactive_docker_command npm -v
  [ ${status} -eq 0 ]
}

@test "Gulp has been installed by NPM and is in the PATH" {
  run run_interactive_docker_command gulp -v
  [ ${status} -eq 0 ]
}


@test "We can start the container in serve mode (default)" {
  clean_testing_docker_containers
  docker run -d --name=${CONTAINER_TEST_NAME} -P ${DOCKER_IMAGE}
  sleep 5 # We need to wait for init of gulp
}

@test "The HTTP server is reachable from outside and serve content" {
  local ALLOCATED_PORT=$(docker port "${CONTAINER_TEST_NAME}" 8000 | cut -d':' -f2)
  curl -I --fail "http://${DOCKER_HOST_IP}:${ALLOCATED_PORT}"
}

@test "The livereload server is reachable from outside" {
  local ALLOCATED_PORT=$(docker port "${CONTAINER_TEST_NAME}" 35729 | cut -d':' -f2)
  curl -I "http://${DOCKER_HOST_IP}:${ALLOCATED_PORT}/livereload.js" # HTTP404 with content
}

@test "I can build my own project image from this one" {
  rm -rf "${TEST_PROJECT}"
  git clone -b asciidoc https://github.com/opendevise/presentation-bespoke-starter "${TEST_PROJECT}"

  echo "FROM ${DOCKER_IMAGE}" >> ${TEST_PROJECT}/Dockerfile

  docker build -t "${DOCKER_IMAGE}-quickstart" "${TEST_PROJECT}/"

}

@test "We can clean the testing environment" {
  rm -rf "${TEST_PROJECT}"
  clean_testing_docker_containers
}
