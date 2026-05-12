FROM alpine:3.20
CMD ["sh","-c","i=0; while :; do i=$((i+1)); echo \"$(date -u +%FT%TZ) level=info msg=\\\"hello from fly\\\" iter=$i\"; [ $((i % 5)) -eq 0 ] && echo \"$(date -u +%FT%TZ) level=error msg=\\\"sample error\\\" iter=$i\" >&2; sleep 5; done"]
