#!/bin/bash

## Récupération des adresses IP distribuées par DHCP
array=`grep ^lease /var/lib/dhcp/dhcpd.leases | cut -d ' ' -f 2 | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq`

## Fonction pour supprimer l'utilisateur
function del_trainee
{
  echo "Suppression de l'utilisateur..."
  userdel -r -f trainee
}

## Fonction pour créer l'utilisateur
function add_trainee
{
  echo "Création du nouvel utilisateur..."
  useradd -m -p $(perl -e 'print crypt($ARGV[0], "password")' 'trainee') trainee
  chown -R trainee /home/trainee
  chmod -R 755 /home/trainee
}

## Passage des commandes sur chaque poste avec SSH
for ip in $array
do
  echo "Connexion SSH sur l'hôte :" $ip
  ## Suppression et création de l'utilisateur
  ssh $ip "$(typeset -f del_trainee); del_trainee"
  ssh $ip "$(typeset -f add_trainee); add_trainee"
  ## Découpage de l'adresse IP
  segment=( ${ip//./ } )
  room=${segment[2]}
  computer=${segment[3]}
  ## Changement du nom de l'hôte
  echo "Changement du nom de l'hôte..."
  if [ $room == 100 ]
  then
    ssh $ip hostnamectl set-hostname ubuntu-A$computer
  else
    ssh $ip hostnamectl set-hostname ubuntu-B$computer
  fi
  ## Redémarrage de l'hôte
  ssh $ip reboot
done
