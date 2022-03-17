#! /bin/bash

VERSION=$1
REPLACES_VERSION=$2
CREATED_AT=$(date "+%D %T")

echo "Creating OLM bundle for version $VERSION replacing version $REPLACES_VERSION"

rm -rf $VERSION/olm
mkdir -p $VERSION/olm

cp -r olm-base/* $VERSION/olm

# Inject RBAC rules
yq ea '.rules as $item ireduce ({}; .rules += $item )' $VERSION/kubernetes/kubernetes.yml | \
  yq ea -i 'select(fileIndex==0).spec.install.spec.permissions = select(fileIndex==1) | select(fileIndex==0)' $VERSION/olm/manifests/clusterserviceversion.yaml -

yq ea -i ".metadata.annotations.containerImage = \"quay.io/keycloak/keycloak-operator:$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".metadata.annotations.createdAt = \"$CREATED_AT\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".metadata.name = \"keycloak-operator.v$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".spec.install.spec.deployments[0].spec.template.spec.containers[0].image = \"quay.io/keycloak/keycloak-operator:$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".spec.replaces = \"$REPLACES_VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml

mv $VERSION/olm/manifests/clusterserviceversion.yaml "$VERSION/olm/manifests/keycloak-operator.v$VERSION.clusterserviceversion.yaml"

[ "$VERSION" = "latest" ] && echo "skip storing version" || echo "$VERSION" > latest_version.txt
