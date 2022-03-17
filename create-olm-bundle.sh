#! /bin/bash

VERSION=$1
REPLACES_VERSION=$2

echo "Creating OLM bundle for version $VERSION replacing version $REPLACES_VERSION"

mkdir -p $VERSION/olm

cp -r olm-base/* $VERSION/olm

# Inject RBAC rules
yq ea '.rules as $item ireduce ({}; .rules += $item )' $VERSION/kubernetes/kubernetes.yml | \
  yq ea -i 'select(fileIndex==0).spec.install.spec.permissions = select(fileIndex==1) | select(fileIndex==0)' $VERSION/olm/manifests/clusterserviceversion.yaml -

# Populate placeholder values
export REPLACE_ME_VERSION=$VERSION
export REPLACE_ME_LAST_VERSION=$REPLACES_VERSION
export REPLACE_ME_CREATED_AT=$(date "+%D %T")

envsubst < "$VERSION/manifests/keycloak-operator.v$VERSION.clusterserviceversion.yaml" > "$VERSION/olm/manifests/clusterserviceversion.yaml"
rm $VERSION/olm/manifests/clusterserviceversion.yaml

# TODO: check if this actually changes the file
[ "$VERSION" = "latest" ] && echo "skip storing version" || echo "$REPLACES_VERSION" > latest_version.txt
