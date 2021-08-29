# exit on the first failure
set -e

# Because of codegen and compile-time postgres connections, we cant't simply ask docker-compose to build everything.
# Instead, we need a step-by step approach (almost like in GitHub Actions, but with local specifics).

# Make sure we have everything we need, and will not wait for something to be downloaded
docker-compose -f dc.prod-local.yml pull postgres

# Start database for compile-time connections (migrations are applied via volumes)
docker-compose -f dc.prod-local.yml up -Vd postgres

# Build backend-artifacts
docker-compose -f dc.prod-local.yml build backend-artifacts

# Save stack depenencies cache
# TODO: check md5 sum before extracting 
# to avoid copying the same archive to the host again (useful only for frequent local docker builds)
id=$(docker create notepad_backend-artifacts)
docker cp $id:/root/stack_dependencies_cache.tar.gz - > ./backend/cache/stack_dependencies_cache.tar.gz.tar
docker rm -v $id


# Build backend
docker-compose -f dc.prod-local.yml build backend

# - pack server binary to a new image

# - linting all the frontend code with elm-review and elm-format
# - remove generated frontend code 
# - extract generated elm files from backend-artifacts and put them to the frontend codebase
# - format and autofix the generated code
# - run frontend tests
# - compile and pack frontend

# Build frontend
docker-compose -f dc.prod-local.yml build frontend

# Stop the database and everything else
docker-compose -f dc.prod-local.yml down -v
