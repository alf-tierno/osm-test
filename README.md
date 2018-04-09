# osm-test

Scripts for testing OSM inserting hackfest3 vnfd and nsd examples, and instantiate.

## Usage

Prepare your VIM. Download and add the image

```
 wget https://osm-download.etsi.org/ftp/osm-3.0-three/1st-hackfest/images/hackfest3-mgmt.qcow2
 openstack image create --file hackfest3-mgmt.qcow2 --public --disk-format qcow2 hackfest3-mgmt 
```

**create_hackfest.sh**

Modify the VIM_xxx variables of create_hackfest.sh with your VIM parameters
Execute ./create_hackfest.sh
It will add the VIM, download the packages from ETSI repository, upload to OSM and instantiate 
the NSD. It will print the needed command to delete, that must be invoked manually

**clean-all.sh**

Deletes database content using the NBI test URL, and deletes instances using RO client (openmano)

