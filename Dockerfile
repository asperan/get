ARG RUBY_VERSION
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS build

COPY ./ /get

WORKDIR /get

RUN gem build -o "git_toolbox.gem"

ARG RUBY_VERSION
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS install

WORKDIR /get

COPY --from=build /get/git_toolbox.gem ./

RUN gem install "git_toolbox.gem"

FROM install AS test

RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/asperan/get-tests.git /test-repository

WORKDIR /test-repository

CMD ./start_test.sh

FROM install AS run

ENTRYPOINT [ "get" ]
