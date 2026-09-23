FROM mysql:8.4.4

VOLUME /data

# change datadir entry in /etc/mysql/my.cnf
COPY config.sh /root/
RUN sed -i 's/\r$//' /root/config.sh \
    && chmod +x /root/config.sh \
    && /root/config.sh

COPY scripts/* /docker-entrypoint-initdb.d/