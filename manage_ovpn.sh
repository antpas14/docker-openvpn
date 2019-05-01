#!/bin/bash

OVPN_DATA="ovpn-data-volume"
ARCH=$(uname -m)
DOCKER_IMAGE="antpas14/openvpn:"$ARCH

main() {
        action=$1
        [ $1 ] || { "Missing action"; exit 1; }
        shift
        case $action in
        "init")
                initialize_server $1
        ;;
        "create_client")
                create_client $1
        ;;
	"list_clients") 
		list_clients
	;;
	"revoke_client")
		revoke_client $1
	;;
	*)
		print_usage
	;;
        esac
}

print_usage() {
	echo -e " - init: initialize server (requires interaction and may take a while on older machines)\n - create_client <client-name>\n - list_clients \n - revoke_client <client-name>" 
}

initialize_server() {
        [ $1 ] || { echo "Insert server hostname/ip address"; exit 1; }
        server_hostname=$1
        docker volume create --name $OVPN_DATA
        docker run -v $OVPN_DATA:/etc/openvpn --rm $DOCKER_IMAGE ovpn_genconfig -u udp://$server_hostname
        docker run -v $OVPN_DATA:/etc/openvpn --rm -it $DOCKER_IMAGE ovpn_initpki nopass
        docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --restart=always --cap-add=NET_ADMIN $DOCKER_IMAGE --name=openvpn
}

create_client() {
	client_name=$1
	check_client_name $client_name

        docker run -v $OVPN_DATA:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa build-client-full $client_name nopass
	docker run -v $OVPN_DATA:/etc/openvpn --rm $DOCKER_IMAGE ovpn_getclient $client_name > ${client_name}.ovpn
}

list_clients() {
	docker run --rm -it -v $OVPN_DATA:/etc/openvpn $DOCKER_IMAGE ovpn_listclients
}

revoke_client() {
	client_name=$1
	check_client_name $client_name

	docker run --rm -it -v $OVPN_DATA:/etc/openvpn $DOCKER_IMAGE ovpn_revokeclient $client_name 
}

check_client_name() {
	[ $1 ] || { print_usage; exit 1; }
}
main $@
