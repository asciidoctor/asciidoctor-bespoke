FROM alpine:latest
MAINTAINER Dan ALLEN <http://mojavelinux.com>
MAINTAINER Damien DUPORTAL <damien.duportal@gmail.com>

ENV QUICKSTART_PATH /quickstart

# Global libs install
RUN apk --update add bash nodejs ruby ruby-io-console ruby-bundler git \
  && npm install -g gulp-cli \
  && git clone -b asciidoc \
    https://github.com/opendevise/presentation-bespoke-starter "${QUICKSTART_PATH}"

# Quickstarter embeding
COPY Gemfile "${QUICKSTART_PATH}/"
WORKDIR "${QUICKSTART_PATH}"
ENV BUNDLE_GEMFILE "${QUICKSTART_PATH}/Gemfile"
ENV BUNDLE_PATH /bundle
RUN bundle install --system \
  && npm install \
  && rm -rf /var/cache/apk/*

# UX : tuning for custom projects
ONBUILD WORKDIR /documents
ONBUILD COPY ./package.json /documents/package.json
ONBUILD RUN npm install
ONBUILD COPY . /documents/

# HTTP server
EXPOSE 8000
# Livereload server
EXPOSE 35729

ENTRYPOINT ["gulp"]
CMD ["serve"]
