from waitress import serve
from application import application

if __name__ == '__main__':
    serve(application, port='5000')