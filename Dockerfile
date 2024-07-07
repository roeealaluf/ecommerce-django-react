FROM python:3.9.6-alpine
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /code
COPY requirements.txt requirements.txt 
RUN apk add -u zlib-dev jpeg-dev gcc musl-dev
RUN pip install --upgrade defusedxml olefile Pillow
RUN python3 -m pip install --upgrade pip
RUN pip install -r requirements.txt
COPY . .
EXPOSE 80
CMD ["python", "manage.py","runserver"]
