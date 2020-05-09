# start from node image so we can install esy from npm
FROM node:12-alpine as build

ENV TERM=dumb LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib

RUN mkdir /esy
WORKDIR /esy

ENV NPM_CONFIG_PREFIX=/esy
RUN npm install -g --unsafe-perm @esy-nightly/esy

# now that we have esy installed we need a proper runtime

FROM alpine:3.8 as builder

ENV TERM=dumb LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib

WORKDIR /

COPY --from=build /esy /esy

RUN apk add --no-cache ca-certificates wget bash curl perl-utils git patch \
    gcc g++ musl-dev make m4 linux-headers coreutils

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk
RUN apk add --no-cache glibc-2.28-r0.apk

ENV PATH=/esy/bin:$PATH

RUN mkdir /app
WORKDIR /app

COPY docker-cache.json /app/package.json
COPY esy.lock /app/esy.lock

RUN esy

COPY . /app

RUN esy install
RUN esy build

RUN esy dune build --profile=docker

RUN esy mv "#{self.target_dir / 'default' / 'executable' / 'ReasonGuestLoginOidcClientApp.exe'}" main.exe

RUN strip main.exe

FROM scratch

WORKDIR /app

COPY --from=esy /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=esy /app/main.exe main.exe

EXPOSE 8080 9443

ENTRYPOINT ["/app/main.exe"]
