FROM busybox

COPY ./build/docs /app

WORKDIR /app
CMD ["busybox", "httpd", "-f", "-v", "-p", "3000"]
