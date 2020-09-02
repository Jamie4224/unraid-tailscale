# Portions Copyright (c) 2020 Tailscale Inc & AUTHORS All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

FROM golang:1.15-alpine AS build-env

WORKDIR /go/src/tailscale

#COPY go.mod .
#COPY go.sum .
RUN apk add git
RUN git clone https://github.com/tailscale/tailscale.git .
RUN git checkout -b v1.05
RUN go mod download

COPY . .

RUN go install -v ./cmd/...

FROM alpine:3.11
RUN apk add --no-cache ca-certificates iptables iproute2
COPY --from=build-env /go/bin/* /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin

RUN echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/00-alpine.conf
RUN echo 0 | tee /proc/sys/net/ipv4/conf/tailscale0/rp_filter
RUN iptables -t nat -A POSTROUTING -j MASQUERADE

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
