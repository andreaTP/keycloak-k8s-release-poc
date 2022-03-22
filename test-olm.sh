docker build -t docker.io/andreatp/keycloak-operator-bundle:latest -f bundle.Dockerfile .

docker push docker.io/andreatp/keycloak-operator-bundle:latest

opm alpha bundle validate --tag docker.io/andreatp/keycloak-operator-bundle:latest --image-builder docker
          