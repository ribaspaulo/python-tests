#FROM python:3.12.2
FROM python:3.12-slim-bullseye

# Crie uma pasta no container vinculada a uma pasta do hospedeiro
RUN pip install --upgrade pip
RUN pip install Flask==3.0.2
RUN pip install secure-smtplib==0.1.1
RUN mkdir srv_email && chmod 777 -R srv_email/
RUN mkdir /srv_email/uploads

COPY  ./*.py /srv_email/


# Defina o diretório de trabalho padrão
WORKDIR /srv_email

#CMD ["python","app.py"]