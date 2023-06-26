ARG RUBY_VERSION
FROM docker.io/library/ruby:${RUBY_VERSION}-slim

# WARNING: 'make' and 'gcc' packages are required for version 3.0 and 3.1;
# remove this line when they are EOL to make the image smaller.
RUN apt-get update && apt-get install -y make gcc git

COPY ./ /get

WORKDIR /get

RUN ./bin/setup

RUN git clone https://github.com/asperan/get-tests.git /test-repository

WORKDIR /test-repository

CMD ./start_test.sh
