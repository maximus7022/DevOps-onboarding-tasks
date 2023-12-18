# build stage
FROM golang:1.21.5-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
COPY main.go ./

RUN go build -o /go-app

# run stage
FROM alpine:latest

COPY --from=builder /go-app /go-app
COPY web ./web/

EXPOSE 8080
CMD [ "/go-app" ]