FROM golang:1.21.5-alpine

WORKDIR /app

COPY go.mod go.sum ./
COPY main.go ./
COPY web ./web/

RUN go build -o /go-app

EXPOSE 8080
CMD [ "/go-app" ]