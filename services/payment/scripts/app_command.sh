#!/bin/sh
              # Start the app
              python infra\scripts\setup_dynamodb.py
              exec uvicorn src.main:app --host 0.0.0.0 --port 8080