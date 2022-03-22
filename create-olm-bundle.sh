#! /bin/bash

VERSION=$1
REPLACES_VERSION=$2
CREATED_AT=$(date "+%D %T")

echo "Creating OLM bundle for version $VERSION replacing version $REPLACES_VERSION"

rm -rf $VERSION/olm
mkdir -p $VERSION/olm

cp -r olm-base/* $VERSION/olm

# Inject RBAC rules
#  | .rules[-1] += "serviceAccountName = keycloak-operator" ??
# TODO: verify better: https://github.com/k8s-operatorhub/community-operators/pull/757/files#diff-5145e4855a6359acb4f5eb9c81e68b56c5aaad6710e986a2dd80a485a15b7d2aR332
yq ea '.rules as $item ireduce ({}; .rules += $item) | .rules[-1] += "serviceAccountName = keycloak-operator" | .' $VERSION/kubernetes/kubernetes.yml | \
  yq ea -i 'select(fileIndex==0).spec.install.spec.permissions[0] = select(fileIndex==1) | select(fileIndex==0)' $VERSION/olm/manifests/clusterserviceversion.yaml -

yq ea -i ".metadata.annotations.containerImage = \"quay.io/keycloak/keycloak-operator:$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".metadata.annotations.createdAt = \"$CREATED_AT\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".metadata.name = \"keycloak-operator.v$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".spec.install.spec.deployments[0].spec.template.spec.containers[0].image = \"quay.io/keycloak/keycloak-operator:$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".spec.replaces = \"keycloak-operator.v$REPLACES_VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml && \
yq ea -i ".spec.version = \"$VERSION\"" $VERSION/olm/manifests/clusterserviceversion.yaml

mv $VERSION/olm/manifests/clusterserviceversion.yaml "$VERSION/olm/manifests/keycloak-operator.v$VERSION.clusterserviceversion.yaml"

cp $VERSION/kubernetes/*.keycloak.org-v1.yml $VERSION/olm/manifests

[ "$VERSION" = "latest" ] && echo "skip storing version" || echo "$VERSION" > latest_version.txt
