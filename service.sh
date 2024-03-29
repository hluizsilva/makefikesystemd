prog="dbaccess7890"

#Inserir o caminho do diretorio do executavel
pathbin="/u02/totvs/dbaccess_7890/multi"

progbin="${pathbin}/${prog}"
pidfile="/var/run/${prog}.pid"
lockfile="/var/lock/subsys/${prog}"

#################################################################
#AMBIENTE COM DB ORACLE
#################################################################
#Variavel EnvOracle define se deve exportar as variaveis do ORACLE
#       1 - Habilitado | 0 - Desabilitado
#################################################################
envOracle=1
#################################################################
oracle_sid="orcl"
oracle_home="/u02/instantclient_19_3"
tns_admin="/u02/instantclient_19_3"


''

#ckconfig: 2345 84 10
#description: Starts and stops DBAccess
#########################################
# CONFIGURACAO DO SERVICO #
#########################################
#Inserir o nome do executavel 
prog="dbaccess64"
#Inserir o caminho do diretorio do executavel
pathbin="/totvs/microsiga/dbaccess"
progbin="${pathbin}/${prog}"
pidfile="/var/run/${prog}.pid"
lockfile="/var/lock/subsys/${prog}"
#################################################################
inteval=3 #Intevalo em segundos para iniciar o serviço durante o restart
#################################################################
#Configuracao de ULIMIT #
#################################################################
#open files - (-n)
openFiles=65536
#stack size - (kbytes, -s)
stackSize=1024
#core file size - (blocks, -c)
coreFileSize=unlimited
#file size - (blocks, -f)
fileSize=unlimited
#cpu time - (seconds, -t)
cpuTime=unlimited
#virtual memory - (-v)
virtualMemory=unlimited
#################################
# FIM DA CONFIGURACAO #
#################################
#################################
#################################
#Source function library.
functions="/etc/init.d/functions"
if [ -e ${functions} ] ; then
. /etc/init.d/functions
else
echo "$functions not installed"
exit 5
fi
RETVAL=0
#Verifica se o executavel tem permissao correta e se esta acessivel
test -x $progbin || { echo "$progbin not installed";
        if [ "$1" = "stop" ]; then exit 0;
        else exit 5; fi; }
#Prepara as ulimit para o servico do DBAccess
ulimit -n ${openFiles}
ulimit -s ${stackSize}
ulimit -c ${coreFileSize}
ulimit -f ${fileSize}
ulimit -t ${cpuTime}
ulimit -v ${virtualMemory}
#Acessa o diretorio configurado na variavel PATHBIN
cd $pathbin
#Variaveis de Output
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
#Function Start
start() {
if [ -z `pidof -x $progbin` ] ; then
   echo "Starting $prog... "
   daemon $progbin >/dev/null &
   #exec ./${prog} >/dev/null &
   RETVAL=$?
   if [ ${RETVAL} -eq 0 ]; then
      touch ${lockfile}
      touch ${pidfile}
      pidof -x ${progbin} > ${pidfile}
      sleep 1
      echo "PID : " `cat ${pidfile}`
      echo "${prog} running :   ${green}[ OK ]${reset}"
   else
      echo "Failed to start ${prog} :         ${red}[ Failure ]${reset}"
   fi 
   echo
else
   echo "$prog is ${green}Started${reset} pid `pidof -x $progbin`"
fi
}
#Function Stop
stop() {
if [ ! -z `pidof -x ${progbin}` ] ; then
   killproc $progbin
   #pkill -f ${prog}
   echo
   rm -f $lockfile
   rm -f $pidfile
   echo -n "Stopping ${prog}."
   while [ ! -z `pidof -x ${progbin}` ]
   do
        echo -n "."
        sleep 1
   done
   echo
   echo "${prog} is Stopped     ${red}[ Stopped ]${reset}"
else
   echo "${prog} is not running ${red}[ Stopped ]${reset}"
fi
}
status() {
pid=$(pidof -x ${progbin})
progport=$(lsof -Pp ${pid} | grep '(LISTEN)' | awk '{ print $9}' | cut -d: -f2 | xargs)
list=$(ps -eo pid,start_time,cputime,pcpu,pmem,stat,size,nlwp,comm | grep ${pid})
start_time=$(echo $list | awk '{ print $2 }')
cputime=$(echo $list | awk '{ print $3 }')
pcpu=$(echo $list | awk '{ print $4 }')
pmem=$(echo $list | awk '{ print $5 }')
stat=$(echo $list | awk '{ print $6 }')
size=$(echo $list | awk '{ print $7 }')
nlwp=$(echo $list | awk '{ print $8 }')
comm=$(echo $list | awk '{ print $9 }')
size=$(echo "$(bc <<< "scale=2;$size/1024") MB")
echo "PROCESS           : ${comm}"
echo "PORT              : ${progport}"
echo "PID               : ${pid}"
echo "STARTED           : ${start_time}"
echo "TIME              : ${cputime}"
echo "%CPU              : ${pcpu}"
echo "%MEM              : ${pmem}"
echo "MEMORY            : ${size}"
echo "STATUS            : ${stat} ${green}[ running ]${reset}"
echo "THREADS           : ${nlwp}"
}
#MAIN
case "$1" in
start)
    start
    ;;
stop)
    stop
    ;;
status)
    if [ ! -z `pidof -x $progbin` ] ; then
       echo "Status process     : ${green}[ OK ]${reset}"
       status
    else
        echo "Status process    : ${red}[ Failure ]${reset}"
        echo "Program $prog is not running!"
    fi
    ;;
restart)
    stop
    sleep $inteval
    start
    sleep $inteval
    status
    ;;
condrestart)
   if test "x`pidof -x $progbin`" != x; then
        stop
        start
    fi
    ;;
*)
    echo $"Usage: $0 {start|stop|restart|condrestart|status}"
    exit 1
esac
exit 0