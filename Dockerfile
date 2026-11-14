FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/emulator

ADD https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator_amd64.deb /opt/aws-emulator.deb

RUN apt update && apt install -y /opt/aws-emulator.deb curl \
    && rm -rf /var/lib/apt/lists/* /opt/aws-emulator.deb \
    && mkdir -p /home/emulator && chown 1000 /home/emulator

USER 1000
EXPOSE 9297
ENTRYPOINT ["aws-emulator", "-b", "0.0.0.0"]
