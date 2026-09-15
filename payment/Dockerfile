#
# Build — uwsgi ships as source and needs a compiler; keep that toolchain
# out of the runtime image entirely rather than leaving gcc installed in
# the final layer.
#
FROM python:3.12-slim-bookworm AS build

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir --user -r requirements.txt

#
# Run
#
FROM python:3.12-slim-bookworm

WORKDIR /app

COPY --from=build /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH

EXPOSE 8080

CMD ["python3", "payment.py"]