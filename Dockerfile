FROM python:3
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /code
RUN apt-get update \
    && apt-get install -y \
        libjpeg-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt requirements.txt 
RUN pip install --upgrade pip
RUN pip install --upgrade defusedxml olefile Pillow
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "manage.py","runserver"]
