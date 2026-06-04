FROM python:3.12
WORKDIR /app
COPY . /app
RUN apt-get -qq update && apt-get -qq install -y git wget ffmpeg mediainfo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs
RUN npm i -g npm
RUN pip install --no-cache-dir -r requirements.txt
ENV PATH=/app:$PATH
EXPOSE 8080
CMD ["bash", "start.sh"]
