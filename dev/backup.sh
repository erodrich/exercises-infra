!/bin/bash

# Read variables from .env file
$_USER = ''
$_CONTAINER_NAME = ''
$_DBNAME = ''

# If variable not found throw error msg

# prompt for options [BACKUP, RESTORE]
# when BACKUP
docker exec exercises-postgres-dev pg_dump -U postgres -F t exercises_dev > exercises_dev_backup.tar   

#docker run --rm -v $(pwd):/backup:Z postgres:latest pg_restore --clean --if-exists -U postgres -d exercises-postgres-dev /backup/exercises_dev_backup.tar
# when RESTORE
docker exec -i exercises-postgres-dev pg_restore -U postgres -d exercises_dev --clean --if-exists < exercises_dev_backup.tar