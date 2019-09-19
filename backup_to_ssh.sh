#!/bin/bash

#Не працює з кириллицею в назвах та пробілами в шляхах та назвах!
#Початкові змінні для скріпта
###Працює без паролів по ссх ключу

server_ip=adler.com.ua			#ір сервака

port=2882				#Порт сервака

login=root				#логін сервака

local_dir=/mnt/d/sftp_backup_adler/	#Директорія локальних бекапів

backup_dir=/home/backup/		#Директорія віддалених бекапів

copy_count=1  				#просто змінна для обрахунку

sleep_count=1				#Змінна для обрахунку

sleep_time=8m				#Затримка на сон якщо файл 1 і треба почекати

waiting_time=4m				#Час затримки при невдалому скачуванні бекапа

#-----------------------------------------------------Функції коду-----------------------------------------------

function indexing {
	echo ==============================
	echo =====  START OF INDEXING OLDER BACKUP
	backup_f=$(ssh $login@$server_ip -p $port "cd "$backup_dir" && ls -t | tail -1") #старіший бекап знаходим
	backup=$backup_dir$backup_f #об'єднуєм директорію і назву файлів
	echo =====  BACKUP FULL NAME "$backup"
	size_serv=$(ssh $login@$server_ip -p $port "wc -c < '$backup'") #дістаєм розмір
	echo =====  SERV SIZE OF BACKUP IS "$size_serv"
	echo ==============================
}

function copying {
	echo =====  START OF COPYING TO LOCAL
 	echo =====  BACKUP FILE "$backup_f". COPYING...
        scp -P $port $login@$server_ip:"$backup" "$local_dir"
	checking
}

function checking {
	echo =====  START OF COMPARING FILES SIZES IN SERV AND LOCAL  =====
	size_local=$(wc -c < "$backup_f")

	if [ $size_serv -eq $size_local ]
	then
		echo =====  LOCAL SIZE OF BACKUP IS $size_local
		echo =====  COMPARING OF FILES SUCCESSFUL  =====
		echo ==============================
		deleting

	elif [ $size_serv -ne $size_local ]
	then

		if [ $copy_count -lt "5" ]
		then
			echo =====  COMPARING OF FILES WAS UNSUCCESSFUL. RETRYING...
			copy_count=$((copy_count+1))		#ЛІЧИЛЬНИК ДЛЯ НЕВДАЧНИХ СПРОБ ВИКАЧКИ.
			sleep $waiting_time
			copying

		elif [ $copy_count -eq "5" ]
		then
			#copy_count=0
			echo =====  BACKUP NOT COPIED FOR 5 TIMES  =====
			echo ============================
		fi
	fi
}

function deleting {
	echo =====  START DELETING OLDER FILE FROM SERV  =====
	ssh $login@$server_ip -p $port " rm -rf $backup"
	echo =====  BACKUP $backup SUCCESSFULLY DELETED...
	echo ============================
}


function start_backuping {
	indexing
	copying
	check_local_size
}

function check_local_size {
	echo =====  CHECKING LOCAL FOLDER SIZE...  =====
	cd "$local_dir"
	local_size=$(ls | wc -l)

	if [ $local_size -gt 7 ]
	then
		#ВИДАЛЯЄМО СТАРІШИЙ 5 ЛОКАЛЬНИЙ БЕКАП.
		old_local_backup=$(ls -t | tail -1)
		rm -rf "$old_local_backup"
		echo =====  DELETED LOCAL FILE "$old_local_backup"
		echo ============================
	fi
}

function main_code {
	cd "$local_dir"
	echo =====  CALCULATING FILES ON SERV  =====
	count_files=$(ssh $login@$server_ip -p $port "cd $backup_dir && ls | wc -l") #кількість файлів у папці бекапів.
	echo =====  $count_files BACKUP FILES ON SERVER

	if [ $count_files -eq 2 ]
        	then
			start_backuping

	elif [ $count_files -eq 1 ]
        	then
			if [ $sleep_count -eq "5" ]
			then
				echo =====  BACKUP CHECKED 5 TIMES AND ARE NOT CREATED. SCRIPT WILL BE RESTARTING AT NEXT DAY  =====
			elif [ $sleep_count -lt "5" ]
			then
				echo =====  ATTEMPT $sleep_count  =====
				echo =====  BACKUP ARE ONE IN FOLDER. WAITING $sleep_time FOR NEW...
                		sleep $sleep_time
				sleep_count=$((sleep_count+1))
				echo ============================
				main_code
			fi

	elif [ $count_files -eq 3 ]
        	then
        	        echo =====  ERROR! BACKUPS FILES ARE 3!
                	indexing
                	echo =====  DELETING UNNEEDED BACKUP
                	deleting
                	main_code
	fi
}

function start_program {
	echo adler_site_backup_script
	echo =====  STARTING TIME $(date)  =====
	main_code
	echo =====  ENDING TIME $(date)  =====
}


######################################################ГОЛОВНИЙ КОД############################################################

start_program


