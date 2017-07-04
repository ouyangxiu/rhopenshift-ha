#!/bin/bash

# This script prepares each host prior to the ansible-installer run
# It's meant to be run as root on the jump box.
# scp this file to jumpbox, run it as root

domain="example.com"

function prepare-jumpbox() {

	
	host=$1
	username=$2
	password=$3
	pool=$4

	echo "preparing host: $host"

	cd /etc/yum.repos.d/
	mv open.repo open.repo.bak

	subscription-manager register --force --username $username --password=$password --name=opentlc-$host
	subscription-manager attach --pool=$pool
	subscription-manager repos --disable="*"
	subscription-manager repos --enable rhel-7-server-ose-3.5-rpms 
	subscription-manager repos --enable rhel-7-fast-datapath-rpms 
	subscription-manager repos --enable rhel-7-server-rpms 
	subscription-manager repos --enable rhel-7-server-optional-rpms 
	subscription-manager repos --enable rhel-7-server-extras-rpms


	echo "installing sos psacct"
	yum install -y sos psacct
	yum update -y
	yum install -y atomic-openshift-excluder atomic-openshift-docker-excluder

	atomic-openshift-excluder unexclude	

	yum install -y atomic-openshift-utils

}


# common preparation for all hosts (including jumbbox)
function prepare-hosts() {

	host=$1
	domain=$2
	username=$3
	password=$4
	pool=$5

	echo "preparing host: $host"

	ssh $host.$domain mv /etc/yum.repos.d/open.repo /etc/yum.repos.d/open.repo.bak

	ssh $host.$domain subscription-manager register --force --username $username --password=$password --name=opentlc-$host 
	ssh $host.$domain subscription-manager attach --pool=$pool
	ssh $host.$domain subscription-manager repos --disable="*"
	ssh $host.$domain subscription-manager repos --enable rhel-7-server-ose-3.5-rpms 
	ssh $host.$domain subscription-manager repos --enable rhel-7-fast-datapath-rpms 
	ssh $host.$domain subscription-manager repos --enable rhel-7-server-rpms 
	ssh $host.$domain subscription-manager repos --enable rhel-7-server-optional-rpms 
	ssh $host.$domain subscription-manager repos --enable rhel-7-server-extras-rpms


	echo "installing sos psacct"
	ssh $host.$domain yum install -y sos psacct
	ssh $host.$domain yum update -y
	ssh $host.$domain yum install -y atomic-openshift-excluder atomic-openshift-docker-excluder

	ssh $host.$domain atomic-openshift-excluder unexclude	

}


echo "Enter the subscription pool id:"
read pool
echo "Enter the subscription username:"
read username
echo "Enter the subscription password:"
read password

if [ "x$pool" == "x" ]; then 
	echo "No pool entered. Exiting..."
	exit;
fi

if [ "x$username" == "x" ]; then 
	echo "No subscription username entered. Exiting..."
	exit;
fi
if [ "x$password" == "x" ]; then 
	echo "No subscription password entered. Exiting..."
	exit;
fi


prepare-jumpbox "jumpbox" $username $password $pool

declare -a hosts=("master1" "node1" "infranode1" "loadbalancer1")
for host in "${hosts[@]}" 
do
	prepare-hosts $host $domain $username $password $pool
done


