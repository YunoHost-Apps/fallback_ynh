# Fallback pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/fallback.svg)](https://dash.yunohost.org/appci/app/fallback) ![](https://ci-apps.yunohost.org/ci/badges/fallback.status.svg) [![](https://ci-apps.yunohost.org/ci/badges/fallback.maintain.svg)](https://github.com/YunoHost/Apps/#what-to-do-if-i-cant-maintain-my-app-anymore-)  
[![Installer Fallback avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.png)](https://install-app.yunohost.org/?app=fallback)

*[Read this readme in english.](./README.md)*

> *Ce package vous permet d'installer Fallback rapidement et simplement sur un serveur YunoHost.  
Si vous n'avez pas YunoHost, merci de regarder [ici](https://yunohost.org/#/install_fr) pour savoir comment l'installer et en profiter.*

## Résumé
Fallback est une application spéciale, uniquement en ligne de commande, qui vous donne le moyen de disposer d'un second serveur que vous pourrez utiliser si le premier tombe en panne.  
Cet autre serveur va vous permettre de déployer une copie de votre serveur pour retrouver vos services internet durant la panne.

**Version embarquée:** 0.91

## Captures d'écran

## Démo

Aucune démo pour cette application.

## Configuration

Après l'installation, vous ne devriez pas avoir quoi que ce soit d'autre à configurer.  
Si vous souhaitez tout de même le faire, vous trouverez la liste des app à sauvegarder dans le fichier `/home/yunohost.app/fallback/app_list` et une configuration globale dans cet autre fichier `/home/yunohost.app/fallback/config.conf`.

## Documentation

 * Documentation YunoHost: Il n'y a pas d'autre documentation, n'hésitez pas à contribuer.

## Fonctionnalités spécifiques à YunoHost

#### Support multi-utilisateurs

Non applicable.

#### Architectures supportées.

* x86-64b - [![](https://ci-apps.yunohost.org/ci/logs/fallback%20%28Apps%29.svg)](https://ci-apps.yunohost.org/ci/apps/fallback/)
* ARMv8-A - [![](https://ci-apps-arm.yunohost.org/ci/logs/fallback%20%28Apps%29.svg)](https://ci-apps-arm.yunohost.org/ci/apps/fallback/)
* Buster x86-64b - [![](https://ci-buster.nohost.me/ci/logs/fallback%20%28Apps%29.svg)](https://ci-buster.nohost.me/ci/apps/fallback/)

## Limitations

## Informations additionnelles

### Comment ça fonctionne

Cette app est consitutée de 2 parties, vous devez l'installer avec l'option `main server` sur votre serveur principal, et une seconde fois, avec l'option `fallback server` sur l'autre serveur, qui vous voulez utiliser comme serveur de secours.
> Vous devriez garder cet autre serveur uniquement pour cet usage. Ou alors pour y mettre quelques autres backups. Et bien sûr, il est préférable que ce serveur soit à un autre endroit.
> Afin de simplifier l'usage des 'actions', le serveur de secours devrait bénéficier d'un nom de domaine associé, comme fallback.mondomain.tld

Après l'installation, chaque nuit, le serveur principal va faire des sauvegardes et les envoyer sur votre serveur de secours.  
Au minimum, il fera une sauvegarde du système. Vous pouvez demander la sauvegarde de vos applications aussi, en éditant le fichier `/home/yunohost.app/fallback/app_list`  
Avant de faire un backup, il vérifiera avec celui de la nuit précédente. Et fera une nouvelle sauvegarde seulement si il y a quelque chose de nouveau. Afin de préserver votre bande passante.
> Ces backups seront chiffrés, sauf si vous avez demandé l'inverse.

Si vous avez un problème avec votre serveur principal, vous pouvez maintenant utiliser votre serveur de secours, restaurer votre sauvegarde de la nuit dernière, et utiliser ce serveur le temps de la panne.  
Voyons comment ça marche.

#### Que dois-je faire en cas de panne de mon serveur principal ?

Voilà, nous y sommes, votre serveur principal est panne, fallait bien que ça arrive !  
Pas d'inquiétude, sautez sur votre serveur de secours et utiliser le script de déploiement.
`/home/yunohost.app/fallback/deploy_fallback`
> Vous pouvez également utiliser l'action 'Deploy the fallback server.' depuis votre panel administrateur.

Ce script va commencer par faire un backup de votre serveur de secours, puis restaurer le backup de votre serveur principal.  
Cette restauration va transformer votre serveur de secours en lui donnant la configuration de votre serveur principal. Ensuite, il va restaurer les applications sélectionnées dans votre fichier app_list.  
A présent, ce serveur va devenir votre serveur principal, recevoir vos mails et faire tourner vos apps.
> En fait, il y a juste un "petit détail", il faut modifier votre dns pour indiquer la nouvelle adresse de votre serveur. Voyons ça à la fin de cette doc.

#### Bon, maintenant mon serveur est réparé. Mais j'ai besoin de récupérer ce qui s'est passé sur mon serveur de secours.

Si vous avez terminé avec votre serveur de secours, utiliser l'autre script, juste à côté du précédent.
`/home/yunohost.app/fallback/close_fallback`
> Vous pouvez également utiliser l'action 'Close the fallback server.' depuis votre panel administrateur.

Ce script va faire un backup du système de votre serveur de secours et des apps précédemment restaurées. Et mettre ces backups de côtés.  

Ensuite, il va nettoyer le système et restaurer le backup créé lors de l'exécution du script `deploy_fallback`. Ainsi, rien ne se sera passé sur ce server.

Donc, toutes vos données produites sur votre serveur de secours sont maintenant mise de côté. Vous attendant gentillement.  
Retourner donc sur votre serveur principal et utiliser ce script.  
`/home/yunohost.app/fallback/update_from_fallback`
> Vous pouvez également utiliser l'action 'Update from your fallback server' depuis votre panel administrateur.

Pour terminer, ce script va télécharger les backups depuis votre serveur de secours et les restaurer sur votre serveur principal. Pour mettre à jour vos données et garder votre serveur principal à jour avec ce que vous avez fait sur le serveur de secours.  
Pour être plus prudent, chaque restauration sera précédée d'un backup, juste au cas où.

#### Et... Comment je suis censé changer mon IP rapidement dans les dns ?

C'est une question difficile...  
Et ça nécessite plus d'expérimentation...  
Mais, il y a un moyen simple de faire ça. Utiliser une entrée de dns dynamique chez votre registrar (si il vous le permet), même si vous avez une IP statique. Et mettez à jour cette IP si vous devez basculer sur votre serveur de secours.  
Selon votre registrar, vous devriez disposer d'un outil en ligne de commande pour faire simplement.

## Liens

 * Reporter un bug: https://github.com/YunoHost-Apps/fallback_ynh/issues
 * Site de Fallback: https://github.com/maniackcrudelis/Fallback-server
 * Site de YunoHost: https://yunohost.org/
