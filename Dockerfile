FROM python:3.9.6

WORKDIR /iiq

COPY requirement.txt /iiq/

RUN pip3 install -r requirement.txt

COPY . /iiq/

EXPOSE 5000

CMD ["python", "be.py"]