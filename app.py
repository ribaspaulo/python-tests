import os
from flask import Flask, request, jsonify
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import json

SRV_PORT = int(os.environ['SRV_PORT'])

app = Flask(__name__)

@app.route("/email", methods=["POST"])
def handle_request():
    data = request.get_json()
    d = data.get("message")

    smtp_server = d["smtp_server"]  # Endereço do servidor SMTP
    smtp_port = d["smtp_port"]  # Porta do servidor SMTP
    sender_email = d["sender_email"]  # Seu endereço de e-mail
    sender_password = d["sender_password"]  # Sua senha de e-mail

    # Destinatário e conteúdo do e-mail
    recipient_email = d["recipient_email"]
    subject = d["subject"]
    message_body = d["message_body"]
    
    try:
        attach_files = d["attach_files"]
    except:
        attach_files = []

    # Crie o objeto MIMEText com o conteúdo da mensagem
    recipient_email = recipient_email.replace(" ","").split(",")
    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] =  ", ".join(recipient_email)
    msg['Subject'] = subject
    msg.attach(MIMEText(str(message_body), 'html'))

    # Itera sobre a lista de arquivos para anexar
    for attach_file in attach_files:
        if len(attach_file) > 4:
            # Abrir o arquivo que será anexado
            try:
                filename = os.path.join('uploads', attach_file)
                attachment = open(filename, 'rb')

                # Criar o objeto MIMEBase
                part = MIMEBase('application', 'octet-stream')
                part.set_payload((attachment).read())

                # Codificar o arquivo em base64
                encoders.encode_base64(part)

                # Adicionar cabeçalho ao anexo
                part.add_header('Content-Disposition', f'attachment; filename={attach_file}')

                # Adicionar o anexo ao corpo do e-mail
                msg.attach(part)
            except Exception as e:
                print(f'Erro ao anexar arquivo {attach_file}: {e}')            

    # Inicialize a conexão SMTP
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()  # Inicie a conexão TLS (opcional)

        # Faça login no servidor SMTP
        server.login(sender_email, sender_password)
        
        try:
            # Envie o e-mail
            server.sendmail(sender_email, recipient_email, msg.as_string())
            r = jsonify({"subject": subject, "recipient_email": recipient_email})
        except Exception as e:
            r = f'Erro ao enviar e-mail: {e}'
        finally:
            server.quit()
    return r

@app.route('/upload', methods=['POST'])
def upload_file():
    if request.method == 'POST':
        # Verifica se algum arquivo foi enviado
        if 'file' not in request.files:
            return 'Erro: nenhum arquivo enviado.'

        files = request.files.getlist('file')
        accepted_files = ['gz', 'zip', '7z']
        uploaded_files = []
        errors = []

        for file in files:
            # Verifica se o arquivo tem uma extensão aceita
            ftype = file.filename.split(".")
            if ftype[-1] in accepted_files:
                # Salva o arquivo na pasta uploads
                file.save(os.path.join('uploads', file.filename))
                uploaded_files.append(file.filename)
            else:
                errors.append(f'Erro: o arquivo {file.filename} não é válido.')

        if errors:
            return jsonify({"success": False, "errors": errors}), 400
        else:
            return jsonify({"success": True, "uploaded_files": uploaded_files}), 200

app.run(host="0.0.0.0", port=SRV_PORT)
