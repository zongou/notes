# https://wiki.termux.com/wiki/Backing_up_Termux

# define presets
backupDir="/storage/emulated/0/termux/backups"
termuxRoot="/data/data/com.termux"

# check session mode
session="NULL"
if command -v termux-info >/dev/null 2>&1; then 
    echo '[NORMAL SESSION]' 
    session="NORMAL"
else 
    echo '[FAILSAFE SESSION]' 
    session="FAILSAFE"
fi

# check storage permission
checkStoragePermission(){
    if [ ! -w /storage/emulated/0 ];then
        echo "Permission denied"
        exit 1
    fi
}
# check if BackupDir exists
checkBackupDir(){
    if [ ! -d $backupDir ];then
        echo "backupDir: "
        echo $backupDir
        echo " not exists"
        # ask if to create dir
        echo "creat backupDir? y/n"
        read answer
        if [ "$answer"x = "y"x ];then 
            mkdir -p $backupDir
            if [ $? -ne 0 ];then
                echo "create dir failed!"
                exit 1
            fi
        else 
            echo "exiting..." && exit 1
        fi
    fi
}
backup(){
    # check if in NORMAL SESSION
    # backup will fail when other linux system is installed, force running in NORMAL SESSION
    if [ "$session"x = "NORMAL"x ];then 
        echo "type the name for backup"
        echo "if empty will use termux.tar.gz"
        read name
        if [ -z $name ];then 
            name="termux.tar.gz"
        fi
        echo "will create "$name
        cleanHistoryAndCache
        echo "backing system up..."
        cd $termuxRoot/files
        tar -czvf $backupDir/$name ./home ./usr
        if [ $? -ne 0 ];then
            echo "make sure running in termux default environment"
            exit 1
        fi
        echo -e "\033[0;32m backing up finished! \033[0m"
    else 
        echo "backup is not supported in [FAILSAFE SESSION], exiting..."
    fi
}

restore(){
    # check if backupDir is empty
    if [ $(ls -l $backupDir | grep "^-" | wc -l) -eq 0 ];then
        # empty
        echo "backupDir is empty! exiting..." && exit 1
    else
        echo "Note: make sure no background program running"
        echo "choose a backup file:"
        ls $backupDir
    fi
    read file
    while [ ! -f $backupDir/$file ]
    do
        echo "no match, try again!"
        read file
    done
    echo "start restoring!"
    # use seperated steps is more compatible for lower version of toybox
    if [ "$session"x = "FAILSAFE"x ];then
        rm -rf $termuxRoot/files/*
        gzip -d -c $backupDir/$file | tar -xvf - -C $termuxRoot/files
    fi
    if [ "$session"x = "NORMAL"x ];then
        cleanAllButKeepCoreFunctions
        tar -xzvf $backupDir/$file -C $termuxRoot/files
    fi
    echo -e "\033[0;32m restoring finished! \033[0m"
}

cleanHistoryAndCache(){
    echo "start cleaning"
    termuxBashHistory=$termuxRoot"/files/home/.bash_history"
    if [ -f $termuxBashHistory ];then
        echo "clean termuxBashHistory"
        rm $termuxBashHistory
    fi
    debianBashHistory=$termuxRoot"/files/home/debian-fs/root/.bash_history"
    if [ -f $debianBashHistory ];then
        echo "clean debianBashHistory"
        rm $debianBashHistory
    fi
    jdtCacheDir=$termuxRoot"/files/home/.config/coc/extensions/coc-java-data"
    if [ -d $jdtCacheDir/jdt_ws_* ];then
        ls $jdtCacheDir/jdt_ws_*
        rm -rf $jdtCacheDir/jdt_ws_*
    fi
}

# clean all but keep core functions, get 'rm' alike effect
cleanAllButKeepCoreFunctions(){
    # clean files dir
    cd $termuxRoot/files
    find * -maxdepth 0 | grep -vw 'usr' | xargs rm -rf
    # clean $PREFIX dir
    cd $termuxRoot/files/usr
    find * -maxdepth 0 | grep -vw '\(bin\|lib\)' | xargs rm -rf
    # clean bin dir
    cd $termuxRoot/files/usr/bin
    find * -maxdepth 0 | grep -vw '\(coreutils\|rm\|xargs\|find\|grep\|tar\|gzip\)' | xargs rm -rf
    # clean lib dir
    cd $termuxRoot/files/usr/lib
    find * -maxdepth 0 | grep -vw '\(libandroid-glob.so\|libtermux-exec.so\|libiconv.so\|libandroid-support.so\|libgmp.so\)' | xargs rm -rf
    # clean none exact utils, aggressively
    cd $termuxRoot/files/usr/bin
    rm coreutils grep xargs find rm ../lib/libgmp.so ../lib/libandroid-support.so

    # dependencies:
    # ls libandroid-support.so libgmp.so
    # rm libgmp.so
    # tar libandroid-glob libtermux-exec.so libiconv.so
}

# start
checkStoragePermission
checkBackupDir
echo "this script will backup/restore termux"
echo "choose to backup or restore"
echo "b to backup, r to restore"
read option
case $option in
    "b") backup
        ;;
    "r") restore
        ;;
    *) echo "no match, quitting!"
        exit
        ;;
esac
