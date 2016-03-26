FROM container4armhf/armhf-alpine:edge

RUN echo "http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# We install docker and then copy the binary aside before removing docker again again
RUN apk --update add docker bash \
     && cp /usr/bin/docker /tmp/docker \
     && apk del -r docker \
     && mv /tmp/docker /usr/bin/docker \
     && rm -rf /var/cache/apk/*

COPY docker-gc /docker-gc

VOLUME /var/lib/docker-gc

CMD ["/docker-gc"]
