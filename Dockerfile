FROM reasonnative/web:4.10.0 as builder

RUN mkdir /app
WORKDIR /app

COPY package.json /app/package.json
COPY esy.lock /app/esy.lock

RUN esy

COPY . /app

RUN esy dune build --profile=docker

RUN esy mv "#{self.target_dir / 'default' / 'executable' / 'MorphOidcClient.exe'}" main.exe

RUN strip main.exe

FROM gcr.io/distroless/static

WORKDIR /app

COPY --from=builder /app/main.exe main.exe

ENTRYPOINT ["/app/main.exe"]
