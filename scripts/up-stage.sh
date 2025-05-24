#!/bin/bash
docker compose -f docker-compose.stage.yml --env-file .env.stage up -d
