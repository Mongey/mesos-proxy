FROM alpine
COPY pkg/linux_amd64/mesos-proxy /
CMD /mesos-proxy
