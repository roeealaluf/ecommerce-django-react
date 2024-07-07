FROM python:3
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /code
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt 
RUN pip install --upgrade pip
RUN pip install --upgrade defusedxml olefile Pillow
COPY . .
CMD ["python", "manage.py","runserver"]
