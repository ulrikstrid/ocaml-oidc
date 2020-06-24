FROM alpine:latest as certs
RUN apk --update add ca-certificates

FROM reasonnative/web:4.10.0 as builder

RUN mkdir /app
WORKDIR /app

COPY package.json esy.lock /app/

RUN esy install
RUN esy build --release

COPY . /app

RUN esy dune build --profile=docker

RUN esy mv "#{self.target_dir / 'default' / 'executable' / 'MorphOidcClient.exe'}" main.exe

RUN strip main.exe

FROM scratch as runtime

ENV OPENSSL_STATIC=1
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_DIR=/etc/ssl/certs
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /app

COPY --from=builder /app/main.exe main.exe

ENTRYPOINT ["/app/main.exe"]
