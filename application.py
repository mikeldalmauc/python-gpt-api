from flask import Flask, jsonify, redirect
from flask_restful import Api, MethodNotAllowed, NotFound
from flask_cors import CORS
from util.common import chatGptApiKey, redisPassword, domain, port, prefix, protocol, build_swagger_config_json
from resources.swaggerConfig import SwaggerConfig
from resources.bookResource import BooksGETResource, BookGETResource, BookPOSTResource, BookPUTResource, BookDELETEResource
from resources.login import LoginResource

from flask_swagger_ui import get_swaggerui_blueprint

# ============================================
# Main
# ============================================
application = Flask(__name__)
app = application
app.config['PROPAGATE_EXCEPTIONS'] = True
CORS(app)
api = Api(app, prefix=prefix, catch_all_404s=True)

# Configuración de JWTManager
jwt = JWTManager(app)  

# Configurar Redis
redis_client = redis.Redis(host='localhost', port=6379, db=0)

# ============================================
# Swagger
# ============================================
build_swagger_config_json()
swaggerui_blueprint = get_swaggerui_blueprint(
     prefix,
     f'{protocol}://{domain}:{port}{prefix}/swagger-config',
      config={
          'app_name': "Flask API",
            "layout": "BaseLayout",
            "docExpansion": "none"
          },
     )
app.register_blueprint(swaggerui_blueprint)

  # ============================================
  # Error Handler
  # ============================================

@app.errorhandler(NotFound)
def handle_method_not_found(e):
    response = jsonify({"message": str(e)})
    response.status_code = 404
    return response

@app.errorhandler(MethodNotAllowed)
def handle_method_not_allowed_error(e):
    response = jsonify({"message": str(e)})
    response.status_code = 405
    return response

@app.route('/')
def redirect_to_prefix():
    if prefix != '':
        return redirect(prefix)

# ============================================
# Add Resource
# ============================================

# GET swagger config
api.add_resource(SwaggerConfig, '/swagger-config')

# GET books
api.add_resource(BooksGETResource, '/books')
api.add_resource(BookGETResource, '/books/<int:id>')

# POST book
api.add_resource(BookPOSTResource, '/books')

# PUT book
api.add_resource(BookPUTResource, '/books/<int:id>')

# DELETE book
api.add_resource(BookDELETEResource, '/books/<int:id>')

# Añadir recurso de inicio de sesión
api.add_resource(LoginResource, '/login', resource_class_args=(redis_client,))

if __name__ == '__main__':
    app.run(debug=True)
