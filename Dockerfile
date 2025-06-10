FROM debian:stable-slim

# COPY source dest
COPY learn-docker /bin/goserver

ENV PORT=8991

CMD ["/bin/goserver"]
