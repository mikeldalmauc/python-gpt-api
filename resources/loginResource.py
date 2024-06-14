from flask_restful import Resource
from flask import request, jsonify
from flask_jwt_extended import create_access_token
import redis

# Conexión a Redis
r = redis.Redis(host='localhost', port=6379, db=0)

class LoginResource(Resource):
    def post(self):
        email = request.json.get('email')
        password = request.json.get('password')
        
        if not username or not password:
            return jsonify({"msg": "Missing email or password"}), 400
        
        stored_password = r.hget(f"email:{email}", "password")
        
        if stored_password and stored_password.decode('utf-8') == password:
            access_token = create_access_token(identity=email)
            return jsonify(access_token=access_token)
        else:
            return jsonify({"msg": "Invalid credentials"}), 401
