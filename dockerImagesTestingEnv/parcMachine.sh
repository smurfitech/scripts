#!/bin/bash

###############################################################
#  TITRE: parc de conteneurs
#
#  AUTEUR:   Ibrahim
#  VERSION: 1.1
#  CREATION: 01/12/2022
#  MODIFIE: 04/12/2022
#
#  DESCRIPTION:
#   mot de passe obtenu par :
#          perl -e 'print crypt("password", "salt"),"\n"'
###############################################################

USERNAME=$(id -nu)


if [ -z "$1" ];then
  echo "
Aide:
  --proxy: pour ajouter le proxycs dans la config docker de manière à faire des push et des pull
  --create-debian: par défaut créé 2 conteneurs debian (sinon préciser le chiffre en argument)
  --create-centos : par défaut créé 2 conteneurs centos (idem préciser une valeur sinon)
  --drop : pour supprimer tous les conteneurs que vous avez créé (uniquement ceux commençant par votre nom de user)
  --start : démarre tous les conteneurs (start) et le service docker si celui-ci n'est pas démarré.
  --recap: recap sur tous les conteneurs réalisé avec ce script pour mon user."
fi

#si besoin de configuration du proxy centrale

if [ "$1" == "--proxy" ];then
	if [ -f /etc/systemd/system/docker.service.d/http-proxy.conf ];then
		sudo rm -f /etc/systemd/system/docker.service.d/http-proxy.conf
		sudo service docker restart
	fi
fi
#création de debian seules
if [ "$1" == "--create-debian" ];then
	nbserv=$2
	[ "$nbserv" == "" ] && nbserv=2
	echo "Installation de l'image "
	docker pull solita/ubuntu-systemd-ssh

	# création des conteneurs
	echo "Création : ${nbserv} conteneurs..."

	# détermination de l'id mini
  	id_first=$(docker ps -a --format "{{ .Names }}" |grep "smurfitech.*-vmparc" | sed s/".*-vmparc"//g  | sort -nr | head -1)
	id_min=$(($id_first+1))

	#détermination de l'id max
	id_max=$(($nbserv + $id_min - 1))

	for i in $( seq $id_min $id_max );do
		echo ""
		echo "=> conteneur ${USERNAME}-deb-vmparc${i}"
    		docker run -tid -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name ${USERNAME}-deb-vmparc${i} solita/ubuntu-systemd-ssh
		echo "    => création de l'utilisateur ${USERNAME}"
		docker exec -ti ${USERNAME}-deb-vmparc${i} /bin/bash -c "useradd -m -p sa3tHJ3/KuYvI ${USERNAME}"
		echo "Installation de votre clé publique ${HOME}/.ssh/id_rsa.pub"
		docker exec -ti ${USERNAME}-deb-vmparc${i} /bin/bash -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown ${USERNAME}:${USERNAME} ${HOME}/.ssh"
		docker cp ${HOME}/.ssh/id_rsa.pub ${USERNAME}-deb-vmparc${i}:${HOME}/.ssh/authorized_keys
		docker exec -ti ${USERNAME}-deb-vmparc${i} /bin/bash -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown ${USERNAME}:${USERNAME} ${HOME}/.ssh/authorized_keys"
		docker exec -ti ${USERNAME}-deb-vmparc${i} /bin/bash -c "echo '${USERNAME}   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
		echo "this is done too"
		docker exec -ti ${USERNAME}-deb-vmparc${i} /bin/bash -c "dpkg-reconfigure openssh-server"
		docker exec -ti ${USERNAME}-deb-vmparc${i} /bin/bash -c "service ssh start"
	done
fi

#création de centos seules
if [ "$1" == "--create-centos" ];then

        nbserv=$2
        [ "$nbserv" == "" ] && nbserv=2

        # rapatriement de l'image si elle n'exsiste pas
        echo "Installation de l'image "
        docker pull priximmo/centos7-systemctl-ssh:v1.1

        # création des conteneurs
        echo "Création : ${nbserv} conteneurs..."

        # détermination de l'id mini
        id_first=$(docker ps -a --format "{{ .Names }}" |grep "smurfitech.*-vmparc" | sed s/".*-vmparc"//g  | sort -nr | head -1)
        id_min=$(($id_first+1))

        #détermination de l'id max
        id_max=$(($nbserv + $id_min - 1))

        for i in $( seq $id_min $id_max );do
                echo ""
                echo "=> conteneur ${USERNAME}-centos-vmparc${i}"
                docker run -tid -v /sys/fs/cgroup:/sys/fs/cgroup:ro --cap-add SYS_ADMIN --privileged --name ${USERNAME}-centos-vmparc${i} priximmo/centos-systemctl-ssh:v1.1
                echo "    => création de l'utilisateur ${USERNAME}"
                docker exec -ti ${USERNAME}-centos-vmparc${i} /bin/bash -c "useradd -m -p sa3tHJ3/KuYvI ${USERNAME}"
                echo "Installation de votre clé publique ${HOME}/.ssh/id_rsa.pub"
                docker exec -ti ${USERNAME}-centos-vmparc${i} /bin/bash -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown ${USERNAME}:${USERNAME} $HOME/.ssh"
                docker cp ${HOME}/.ssh/id_rsa.pub ${USERNAME}-centos-vmparc${i}:${HOME}/.ssh/authorized_keys
                docker exec -ti ${USERNAME}-centos-vmparc${i} /bin/bash -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown ${USERNAME}:${USERNAME} ${HOME}/.ssh/authorized_keys"
                docker exec -ti ${USERNAME}-centos-vmparc${i} /bin/bash -c "echo '${USERNAME}   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
                docker exec -ti ${USERNAME}-centos-vmparc${i} /bin/bash -c "service ssh start"
        done
fi

# drop des conteneurs du user
if [ "$1" == "--drop" ];then

        for i in $(docker ps -a --format "{{ .Names }}" |grep "${USERNAME}.*-vmparc" );do
                echo "     --Arrêt de ${i}..."
                docker stop $i
                echo "     --Suppression de ${i}..."
                docker rm $i
                done

fi

# démarrage des conteneur (et de docker si nécessaire):

if [ "$1" == "--start" ];then

        sudo /etc/init.d/docker start


        for i in $(docker ps -a --format "{{ .Names }}" |grep "${USERNAME}.*-vmparc" );do
                echo "     --Démarrage de ${i}..."
                docker start $i
        done
fi
# récap des infos:
echo ""
echo "#### Récap des conteneurs de tests ####"
echo ""


        for i in $(docker ps -a --format "{{ .Names }}" |grep "vmparc" );do
                infos_conteneur=$(docker inspect -f '   => {{.Name}} - {{.NetworkSettings.IPAddress }}' ${i})
                echo "${infos_conteneur} - Utilisateur : ${USERNAME} / mdp:password"
        done
