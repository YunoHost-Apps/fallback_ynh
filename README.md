Fallback for YunoHost
==================

Fallback is a special app, only by command line interface, which provide a way to have a secondary server which you can used if your main server goes down.  
This other server will allow you to deploy a copy of your server to bring back you to internet during your break down.

More information below.

[Yunohost project](https://yunohost.org/#/)

https://github.com/maniackcrudelis/Fallback-server

**Upgrade this package:**  
`sudo yunohost app upgrade fallback -u https://github.com/YunoHost-Apps/fallback_ynh`

**Package state:**  
*[Last continuous integration test](https://ci-apps.yunohost.org/jenkins/job/fallback%20%28Community%29/lastBuild/consoleFull)*

---

## How it works

This app is made of 2 parts, you have to install it with the `main server` option on your main server, and again, with the `fallback server` option on the other server you want to use as rescue server.
> You should keep this other server only for that purpose. And maybe also to make some other backups. And it's obviously better if you can have this other server in another place that the previous one.

After the installation, every night, the main server will make some backups and send them to your fallback server.  
At least, it'll make a backup of your system. You can ask to backup your apps too, by editing the file `/home/yunohost.app/fallback/app_list`  
Before make any backup, it will compare with the last backup. And will make a new one, only if there any news on it. Just to preserve your bandwith.
> These backups will be encrypted, unless you ask to not.

If you have an issue with your main server, so you can use your fallback server and restore your nightly backups and run with this server during your break down.  
Let's see how this works.

#### What I have to do in case of break down of my main server ?

So, here we are, you have a failure with your main server. That had to happen !  
Don't worry, jump on your fallback server and use the deploy script.
`/home/yunohost.app/fallback/deploy_fallback`

This script will backup your fallback server first and then restore the backup from your main server.  
This restore will change your fallback server and give him the configuration of your main server, and restore the apps you've selected in your app_list.  
Now this server will became your main server, received your emails and run your apps.
> In fact, there just a "small thing", you have to change your dns to indicate the new IP of your server. Let's see that at the end of this doc please.

#### So, now my main server is fixed. But I need to get all the stuff happened on the fallback.

If you're done with your fallback server, use the other script, just next to the previous one.
`/home/yunohost.app/fallback/close_fallback`

This script will backup your fallback system and the apps you've previously restored on it. And put all of that aside.  
Then, it will remove all of that of your system and restore the backup it made when you used `deploy_fallback`. Like that, nothing happenned on this server.

So, all your data produced on your fallback are now aside. Waiting for you.  
Return on your main server, and use this script.  
`/home/yunohost.app/fallback/update_from_fallback`

To finish, this script will get the backups from the fallback and restore them on your main server. To update your data and keep your main server up to date with what you've done on your fallback.  
To be more carefull, each restoration will be preceed by a backup. Just in case.

#### And... How I'm supposed to change my IP quickly in all the dns ?

That's a difficult question...  
And that needs more experimentation...  
But, there a way to do that simply. Use a dynamic dns entry at your registrar (if it allow it), even if you have a static ip. And update this ip if you have to switch to your fallback.  
Depend of your registrar, you should have a CLI tools to do that simplier.

---

## Comment ça fonctionne

Cette app est consitutée de 2 parties, vous devez l'installer avec l'option `main server` sur votre serveur principal, et une seconde fois, avec l'option `fallback server` sur l'autre serveur, qui vous voulez utiliser comme serveur de secours.
> Vous devriez garder cet autre serveur uniquement pour cet usage. Ou alors pour y mettre quelques autres backups Et bien sûr, il est préférable que ce serveur soit à un autre endroit.

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

Ce script va commencer par faire un backup de votre serveur de secours, puis restaurer le backup de votre serveur principal.  
Cette restauration va transformer votre serveur de secours en lui donnant la configuration de votre serveur principal. Ensuite, il va restaurer les applications sélectionnées dans votre fichier app_list.  
A présent, ce serveur va devenir votre serveur principal, recevoir vos mails et faire tourner vos apps.
> En fait, il y a juste un "petit détail", il faut modifier votre dns pour indiquer la nouvelle adresse de votre serveur. Voyons ça à la fin de cette doc.

#### Bon, maintenant mon serveur est réparé. Mais j'ai besoin de récupérer ce qui s'est passé sur mon serveur de secours.

Si vous avez terminé avec votre serveur de secours, utiliser l'autre script, juste à côté du précédent.
`/home/yunohost.app/fallback/close_fallback`

Ce script va faire un backup du système de votre serveur de secours et des apps précédemment restaurées. Et mettre ces backups de côtés.  

Ensuite, il va nettoyer le système et restaurer le backup créé lors de l'exécution du script `deploy_fallback`. Ainsi, rien ne se sera passé sur ce server.

Donc, toutes vos données produites sur votre serveur de secours sont maintenant mise de côté. Vous attendant gentillement.  
Retourner donc sur votre serveur principal et utiliser ce script.  
`/home/yunohost.app/fallback/update_from_fallback`

Pour terminer, ce script va télécharger les backups depuis votre serveur de secours et les restaurer sur votre serveur principal. Pour mettre à jour vos données et garder votre serveur principal à jour avec ce que vous avez fait sur le serveur de secours.  
Pour être plus prudent, chaque restauration sera précédée d'un backup, juste au cas où.

#### Et... Comment je suis censé changer mon IP rapidement dans les dns ?

C'est une question difficile...  
Et ça nécessite plus d'expérimentation...  
Mais, il y a un moyen simple de faire ça. Utiliser une entrée de dns dynamique chez votre registrar (si il vous le permet), même si vous avez une IP statique. Et mettez à jour cette IP si vous devez basculer sur votre serveur de secours.  
Selon votre registrar, vous devriez disposer d'un outil en ligne de commande pour faire simplement.
