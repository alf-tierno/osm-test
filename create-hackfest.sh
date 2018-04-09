#! /bin/bash

export NBI_URL=https://localhost:9999/osm
USERNAME=admin
PASSWORD=admin
PROJECT=admin

export OSM_HOST=localhost
#export OSM_SOL005=True
export OPENMANO_PORT=9090
export OSM_RO_PORT=9090
export OSM_SO_PORT=9999
export OPENMANO_HOST=localhost

# USe your own VIM values
VIM_NAME=ost2-mrt-tid   #OST2_MRT  #ost2-mrt-tid
VIM_URL=http://openstack-server:5000/v2.0
VIM_TYPE=openstack
VIM_TENANT=tenant_name
VIM_USER=user
VIM_PASSWORD=password
VIM_CONFIG="{use_floating_ip: true}"

export OPENMANO_TENANT=osm
export OPENMANO_DATACENTER=$VIM_NAME


mkdir -p temp
pushd temp

openmano tenant-list osm 2>/dev/null || openmano tenant-create  osm --description osm

openmano datacenter-list --all $VIM_NAME 2>/dev/null || openmano datacenter-create $VIM_NAME "$VIM_URL" --type "$VIM_TYPE"
openmano datacenter-list $VIM_NAME 2>/dev/null || openmano datacenter-attach $VIM_NAME --vim-tenant-name="$VIM_TENANT" --user="$VIM_USER" --password="$VIM_PASSWORD" --config="$VIM_CONFIG"

VNFD1=./hackfest_3charmed_vnfd.tar.gz
NSD1=./hackfest_3charmed_nsd.tar.gz

[ -f "$VNFD1" ] ||  wget https://osm-download.etsi.org/ftp/osm-3.0-three/1st-hackfest/packages/hackfest_3charmed_nsd.tar.gz
[ -f "$NSD1"  ] || wget https://osm-download.etsi.org/ftp/osm-3.0-three/1st-hackfest/packages/hackfest_3charmed_vnfd.tar.gz

[ -f "$VNFD1" ] || ! echo "not found hackfest_3charmed_vnfd.tar.gz Set variable to a proper location" || exit 1
[ -f "$NSD1" ]  || ! echo "not found hackfest_3charmed_nsd.tar.gz Set DESCRIPTORS variable to a proper location" || exit 1

#get token
TOKEN=`curl --insecure -H "Content-Type: application/yaml" -H "Accept: application/yaml"  \
    --data "{username: $USERNAME, password: $PASSWORD, project_id: $PROJECT}" \
    ${NBI_URL}/admin/v1/tokens 2>/dev/null | awk '($1=="_id:"){print $2}'`;
echo export TOKEN=$TOKEN

# VNFD
#########
#insert PKG
echo
echo Uploading VNFD=$VNFD1
curl --insecure -w "%{http_code}\n" -H "Content-Type: application/gzip" -H "Accept: application/yaml" \
    -H "Authorization: Bearer $TOKEN"   --data-binary "@$VNFD1" ${NBI_URL}/vnfpkgm/v1/vnf_packages_content 2>/dev/null
VNFD1_ID=`curl --insecure -w "%{http_code}\n" -H "Content-Type: application/gzip" -H "Accept: application/yaml" \
    -H "Authorization: Bearer $TOKEN"  ${NBI_URL}/vnfpkgm/v1/vnf_packages_content?id=hackfest3charmed-vnf  2>/dev/null \
    | awk '($1=="_id:"){print $2}'`

[ -z "$VNFD1_ID" ] && ! echo VNFD hackfest3charmed-vnf not uploaeded && exit 1
echo "export VNFD1_ID=$VNFD1_ID   # (hackfest3charmed-vnf)"

# NSD
#########
#insert PKG
echo
echo Uploading NSD=$NSD1
curl --insecure -w "%{http_code}\n" -H "Content-Type: application/gzip" -H "Accept: application/yaml" \
    -H "Authorization: Bearer $TOKEN"   --data-binary "@$NSD1" ${NBI_URL}/nsd/v1/ns_descriptors_content 2>/dev/null
NSD1_ID=`curl --insecure -w "%{http_code}\n" -H "Content-Type: application/gzip" -H "Accept: application/yaml" \
    -H "Authorization: Bearer $TOKEN"  ${NBI_URL}/nsd/v1/ns_descriptors_content?id=hackfest3charmed-ns 2>/dev/null \
    | awk '($1=="_id:"){print $2}'`

[ -z "$NSD1_ID" ] && ! echo NSD hackfest3charmed-ns not uploaeded && exit 1
echo "export NSD1_ID=$NSD1_ID   # (hackfest3charmed-ns)"



# NSRS
##############
#add nsr
NSNAME="NSNAME"  #do not use blanks
echo
echo Creating  NSR=$NSNAME
curl --insecure -w "%{http_code}\n" -H "Content-Type: application/yaml" -H "Accept: application/yaml"  -H "Authorization: Bearer $TOKEN"  \
    --data "{ nsDescription: default description, nsName: $NSNAME, nsdId: $NSD1_ID, vimAccountId: $VIM_NAME }" \
    ${NBI_URL}/nslcm/v1/ns_instances_content 2>/dev/null

NSR1_ID=`curl --insecure -w "%{http_code}\n" -H "Content-Type: application/yaml" -H "Accept: application/yaml" -H "Authorization: Bearer $TOKEN" \
    ${NBI_URL}/nslcm/v1/ns_instances_content?name=$NSNAME 2>/dev/null   | grep "^    _id" | awk '($1=="_id:"){print $2}'` ;

echo "export NSR1_ID=$NSR1_ID     # (hackfest_nsr)"

echo
echo DONE
echo
echo "to check run:"
echo 'curl --insecure -w "%{http_code}\n" -H "Content-Type: application/yaml" -H "Accept: application/yaml" -H "Authorization: Bearer '$TOKEN'"  '${NBI_URL}'/nslcm/v1/ns_instances_content/'$NSR1_ID' 2>/dev/null | grep -e detailed-status -e operational-status -e config-status'
echo
echo "to delete run:"
echo 'curl --insecure -w "%{http_code}\n" -H "Content-Type: application/yaml" -H "Accept: application/yaml" -H "Authorization: Bearer '$TOKEN'"  '${NBI_URL}'/nslcm/v1/ns_instances_content/'$NSR1_ID' -X DELETE 2>/dev/null'
echo
echo "to force cleaning run script clean-all.sh"


popd


