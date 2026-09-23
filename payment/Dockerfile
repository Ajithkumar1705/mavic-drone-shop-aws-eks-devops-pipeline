#
# Build — uwsgi ships as source and needs a compiler; keep that toolchain
# out of the runtime image entirely rather than leaving gcc installed in
# the final layer.
#
FROM python:3.12.9-slim-bookworm AS build

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

#
# Run
#
FROM python:3.12.9-slim-bookworm

WORKDIR /app

RUN useradd --create-home --shell /usr/sbin/nologin appuser
COPY --from=build /opt/venv /opt/venv
COPY --chown=appuser:appuser . .

ENV PATH=/opt/venv/bin:$PATH

USER appuser

EXPOSE 8080

CMD ["python3", "payment.py"]