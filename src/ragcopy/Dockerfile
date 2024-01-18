FROM python:3

WORKDIR /opt/ragcopy
COPY . .
RUN pip3 install -r requirements.txt && \
    cp ragcopy.py /usr/local/bin/ragcopy

ENTRYPOINT ["ragcopy"]
