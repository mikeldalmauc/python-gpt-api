- [Python flask app](#python-flask-app)
  - [deploy](#deploy)
- [AWS](#aws)
  - [public EC2 instance DNS](#public-ec2-instance-dns)
  - [Connect to machine through ssh](#connect-to-machine-through-ssh)


# Python flask app 

Refer to the [following guide](https://github.com/geeekfa/Api-Flask)

## deploy

To deploy the app to a server, create a requirements.txt like this:

```bash
pip3 freeze > requirements.txt
```

After deploying app to the server, open a terminal in the server and install the libraries by the following command:

```bash
pip3 install -r requirements.txt
```

Build the docker app.

```bash
sudo docker build -t api-flask .
```
# AWS 

## public EC2 instance DNS

ec2-35-181-229-140.eu-west-3.compute.amazonaws.com

## Connect to machine through ssh

```bash
ssh -i "aws-flask-gpt-api.pem" ec2-user@ec2-35-181-229-140.eu-west-3.compute.amazonaws.com
```