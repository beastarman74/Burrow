FROM alpine:latest

RUN apk add --no-cache \
    autossh \
    openssh-client \
    bash \
	tzdata \
    dos2unix

WORKDIR /app
COPY entrypoint.sh .
COPY healthcheck.sh .
RUN dos2unix entrypoint.sh && chmod +x entrypoint.sh
RUN dos2unix healthcheck.sh && chmod +x healthcheck.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/app/entrypoint.sh"]
