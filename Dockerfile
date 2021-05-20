FROM amazon/aws-cli:latest

RUN yum install -y gzip
COPY resync.sh /usr/sbin/resync.sh
RUN chmod +x /usr/sbin/resync.sh

ENTRYPOINT /usr/sbin/resync.sh
