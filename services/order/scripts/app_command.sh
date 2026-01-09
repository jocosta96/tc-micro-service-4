#!/bin/sh
              # Start the app
              python infra/scripts/database_migration.py init
              exec uvicorn src.main:app --host 0.0.0.0 --port 8080