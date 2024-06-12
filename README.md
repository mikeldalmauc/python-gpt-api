- [Python flask app](#python-flask-app)
  - [Run flask with gunicorn](#run-flask-with-gunicorn)
  - [deploy](#deploy)
- [AWS](#aws)
  - [public EC2 instance DNS](#public-ec2-instance-dns)
  - [Connect to machine through ssh](#connect-to-machine-through-ssh)
  - [Configure compose service on startup](#configure-compose-service-on-startup)


# Python flask app 

Refer to the [following guide](https://github.com/geeekfa/Api-Flask)

## Run flask with gunicorn

```bash
gunicorn application:app -b localhost:5000
```

## deploy

To deploy the app to a server, create a requirements.txt like this:

```bash
pip3 freeze > requirements.txt
```

After deploying app to the server, open a terminal in the server and install the libraries by the following command:

```bash
pip3 install -r requirements.txt
```

Build the docker-compose app.

```bash
docker-compose up -d --build
```
# AWS 

## public EC2 instance DNS

ec2-{ip}.eu-west-3.compute.amazonaws.com

## Connect to machine through ssh

```bash
ssh -i "aws-flask-gpt-api.pem" ec2-user@ec2-{ip}.eu-west-3.compute.amazonaws.com
```

## Configure compose service on startup

Create the file with the service configuration, the content can be found at [docker-compose-app.service](production/docker-compose-app.service)

```bash
sudo nano /etc/systemd/system/docker-compose-app.service
```

Enable and start the service

```bash
sudo systemctl enable docker-compose-app.service
sudo systemctl start docker-compose-app.service
```

Check the service started correctly

```bash
docker ps
```