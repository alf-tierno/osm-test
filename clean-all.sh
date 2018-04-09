#! /bin/bash

export NBI_URL=https://localhost:9999/osm
USERNAME=admin
PASSWORD=admin
PROJECT=admin

export OSM_HOST=localhost
#export OSM_SOL005=True
export OPENMANO_PORT=9090
export OPENMANO_HOST=localhost

# USe your own VIM values
VIM_NAME=ost2-mrt-tid   #OST2_MRT  #ost2-mrt-tid

export OPENMANO_TENANT=osm
export OPENMANO_DATACENTER=$VIM_NAME

    for i in instance-scenario scenario vnf
    do
        for f in `openmano $i-list | awk '{print $1}'`
        do
            [[ -n "$f" ]] && [[ "$f" != No ]] && openmano ${i}-delete -f ${f}
        done
    done

curl --insecure ${NBI_URL}/test/db-clear/nsrs
curl --insecure ${NBI_URL}/test/db-clear/nsds
curl --insecure ${NBI_URL}/test/db-clear/vnfds


#juju destroy-model -y default
#juju add-model default

