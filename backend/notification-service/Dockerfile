FROM golang:1.26-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o /worker ./cmd/worker

FROM alpine:3.20

RUN apk add --no-cache ca-certificates

COPY --from=builder /worker /worker

EXPOSE 8080

CMD ["/worker"]
