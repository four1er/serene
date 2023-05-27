FROM docker.io/python

WORKDIR /app
COPY . .
RUN pip install -r docs/requirements.txt
RUN mkdocs build


FROM docker.io/busybox

COPY --from=0 /app/build/docs /app

WORKDIR /app
CMD ["busybox", "httpd", "-f", "-v", "-p", "3000"]
