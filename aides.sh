#!/bin/bash

date=$(date +"%m-%d-%Y")
emailTo="demoserver@mailinator.com"
emailFrom="no-reply@taratasy.mg"
subject="[WARNING] `hostname` AIDE CHECK DAILY REPORT ${date}"
subjectNO="[INFO] `hostname` AIDE CHECK DAILY REPORT ${date}"
aideDb="/var/lib/aide/aide.db.gz"
aideNewDb="/var/lib/aide/aide.db.new.gz"
aideCheck="/usr/sbin/aide -c /etc/aide.conf"
aideDbStock="/var/lib/aide/aide-db"
aideTmp="/var/lib/aide/aide-tmp"
 
aide_scan(){
# Tester si le base signature est present ou pas.
if  [ ! -f ${aideDb} ]
then
# Création s'il ne trouve pas dans le chemin spécifique /var/lib/aide/.
${aideCheck} --init
# Copie avec le nom prise en charge par Aide (aide.db.gz).
cp -p ${aideNewDb} ${aideDb}
# Sinon on passe au vérification des modifications présent dans votre serveur.
else
echo "Aide check !! ${date}" > ${aideTmp}/aide-${date}.txt
echo "" >> ${aideTmp}/aide-${date}.txt
echo "----------------------Début de Check----------------------" >> ${aideTmp}/aide-${date}.txt
echo "" >> ${aideTmp}/aide-${date}.txt
${aideCheck} --check >> ${aideTmp}/aide-${date}.txt
   if [ ! -d ${aideDbStock} ]
   then
      mkdir ${aideDbStock}
   else
      echo "Le dossier ${aideDbStock} est déjà existé"
   fi
cp -p ${aideDb} ${aideDbStock}/aide.db-${date}.gz
${aideCheck} --update > /dev/null
cp -p ${aideNewDb} ${aideDb}
fi

}

# Fonction pour verifié le log s'il y a des modification detecté
aide_report(){

if [ `cat ${aideTmp}/aide-${date}.txt | grep "AIDE found differences" | wc -l` != 0 ]
then 
    cat ${aideTmp}/aide-${date}.txt | mail -s "${subject}" -r ${emailFrom} ${emailTo} -A ${aideTmp}/aide-${date}.txt
else 
    echo -e "Bonjour,\n\nNous avons pas trouvé des modification sur votre serveur.\n\n Bonne journée." | mail -s "${subjectNO}" -r ${emailFrom} ${emailTo}
fi
echo "" >> ${aideTmp}/aide-${date}.txt
echo "----------------------Check Done----------------------" >> ${aideTmp}/aide-${date}.txt
}

aide_delete(){
# Suppression des fichier base signature plus anciens (plus de 7 jours) 
sudo find ${aideDbStock} -type f -name .gz -mtime +7 -exec rm -f {} +
# Suppression des fichier log plus anciens (plus de 7 jours)
sudo find ${aideTmp} -type f -name .txt -mtime +7 -exec rm -f {} +
}

#Execution des fonctions
aide_scan
aide_report
aide_delete
