import dotenv
import os
import json

class ENVIRONMENT:
    def __init__(self):
        project_dir = os.path.join(os.path.dirname(__file__), os.pardir)
        dotenv_path = os.path.join(project_dir, '.env')
        dotenv.load_dotenv(dotenv_path)
        self.domain = os.getenv("DOMAIN")
        self.port = os.getenv("PORT")
        self.prefix = os.getenv("PREFIX")
        self.protocol = os.getenv("PROTOCOL")
        self.chatGptApiKey = os.getenv("CHAT_GPT_API_KEY")
        self.redisPassword = os.getenv("REDIS_PASSWORD")

    def get_instance(self):
        if not hasattr(self, "_instance"):
            self._instance = ENVIRONMENT()
        return self._instance

    def getDomain(self):
        return self.domain

    def getPort(self):
        return self.port

    def getPrefix(self):
        return self.prefix

    def getProtocol(self):
        return self.protocol

    def getRedisPassword(self):
        return self.redisPassword

    def getGptApiKet(self):
        return self.chatGptApiKey

domain = ENVIRONMENT().get_instance().getDomain()
port = ENVIRONMENT().get_instance().getPort()
prefix = ENVIRONMENT().get_instance().getPrefix()
protocol = ENVIRONMENT().get_instance().getProtocol()
chatGptApiKey = ENVIRONMENT().get_instance().getGptApiKet()
redisPassword = ENVIRONMENT().get_instance().getRedisPassword()

def build_swagger_config_json():
    config_file_path = 'static/swagger/config.json'

    with open(config_file_path, 'r') as file:
        config_data = json.load(file)

    config_data['servers'] = [
        {"url": f"{protocol}://localhost:{port}{prefix}"},
        {"url": f"{protocol}://{domain}:{port}{prefix}"}
    ]

    new_config_file_path = 'static/swagger/config.json'

    with open(new_config_file_path, 'w') as new_file:
        json.dump(config_data, new_file, indent=2)
