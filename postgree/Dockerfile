FROM postgres:13.0-alpine

RUN apk add --no-cache curl jq

COPY db-auth.sh /
RUN chmod +x /db-auth.sh

CMD ["postgres"]