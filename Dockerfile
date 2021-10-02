FROM golang:latest as build
RUN mkdir -p /go/src/github.com/sunet/sigill
ADD . /go/src/github.com/sunet/hsmca/
WORKDIR /go/src/github.com/sunet/hsmca
RUN make
RUN env GOBIN=/usr/bin go install ./cmd/sigill

# Now copy it into our base image.
FROM gcr.io/distroless/base:debug
COPY --from=build /usr/bin/hsmca /usr/bin/hsmca

ENTRYPOINT ["/usr/bin/hsmca"]
