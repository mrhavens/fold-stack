#!/bin/bash
rsync -avz volumes/ user@prod-server:/path/to/fold-stack/volumes/
ssh user@prod-server 'cd /path/to/fold-stack && ./scripts/up-prod.sh'
