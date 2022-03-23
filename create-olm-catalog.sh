
rm -rf catalog
mkdir -p catalog/test-catalog

cd catalog

opm generate dockerfile test-catalog

opm init keycloak-operator \
    --default-channel=alpha \
    --output yaml > test-catalog/operator.yaml

opm render docker.io/andreatp/keycloak-operator-bundle:latest \
    --output=yaml >> test-catalog/operator.yaml

cat << EOF >> test-catalog/operator.yaml
---
schema: olm.channel
package: keycloak-operator
name: alpha
entries:
  - name: keycloak-operator.v17.0.0
EOF

opm validate test-catalog

docker build -f test-catalog.Dockerfile -t docker.io/andreatp/keycloak-catalog:latest .
docker push docker.io/andreatp/keycloak-catalog:latest
