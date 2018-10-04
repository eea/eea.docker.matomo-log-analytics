
FROM python:2-alpine
LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"


RUN apk --update add --no-cache --virtual .run-deps git bash curl coreutils grep \ 
  && wget -O /import_logs.py https://raw.githubusercontent.com/matomo-org/matomo-log-analytics/master/import_logs.py


COPY docker-entrypoint.sh /

VOLUME ["/analytics"]

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["run"]
