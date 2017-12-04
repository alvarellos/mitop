#!/bin/bash

blue=$(tput setaf 4)
yellow=$(tput setaf 3)
normal=$(tput sgr0)

echo -e '\e[1m\e[33m-------------------------------------------------'
printf "%30s\n" "${blue}PED1 ${normal}mitop"

echo -e '\e[1m\e[33m-------------------------------------------------'
echo -e '\e[1m\e[34mAmpliacion de Sistemas Operativos Uned' 
echo -e 'Diego Diaz Alvarellos'
echo 'Curso 2016-2017'
echo -e '\e[1m\e[33m-------------------------------------------------'
printf "${normal}"


# Anular la trampa
# top -n 1

# 1. Obtener PID de procesos del sistema (directorio /proc)

cd /proc
pids=($(ls -d *| grep -o '[0-9]*'))

# Se cuentan las líneas (número total de procesos)
pidsTotal=${#pids[@]}

# ------------------------------------------------------------------------------

# 2. Primera lectura de tiempos de ejecución (instante 1)
# 2.1. Para cada PID. Cálculo del tiempo de ejecución de un proceso en modo usuario y en modo núcleo

for (( i=0; i<${pidsTotal}; i++));

	do
		if [ -f /proc/${pids[i]}/stat ]; then
			modoNucleo[i]=`cat /proc/${pids[i]}/stat | awk '{print $14}'`
			modoUsuario[i]=`cat /proc/${pids[i]}/stat | awk '{print $15}'`
			tiempo1[i]=$((${modoNucleo[i]}+${modoUsuario[i]}))
		fi
done

# 2.2. Tiempo de uso del procesador antes del sleep

declare -i tiempoCPU1=`cat /proc/uptime | cut -f1 -d " " | sed 's/\.//'`

# ------------------------------------------------------------------------------
# 3. Se espera un segundo

sleep 1

# ------------------------------------------------------------------------------

# 4. Segunda lectura de tiempos de ejecución (instante 2)

# 4.1 Tiempo de ejecución de un proceso en modo usuario y en modo núcleo

for (( i=0; i<${pidsTotal}; i++));

	do
		if [ -f /proc/${pids[i]}/stat ]; then
			modoNucleo[i]=`cat /proc/${pids[i]}/stat | awk '{print $14}'`
			modoUsuario[i]=`cat /proc/${pids[i]}/stat | awk '{print $15}'`
			tiempo2[i]=$((${modoNucleo[i]}+${modoUsuario[i]}))
		fi
done


# 4.2. Diferencia de los valores tomados en el instante 1 y en el instante 2 de los procesos

for (( i=0; i<${pidsTotal}; i++ ));
	do
		tiempoInicial=${tiempo1[i]}
		tiempoFinal=${tiempo2[i]}
		diferencia[i]=$((tiempoFinal-tiempoInicial))
done

# 4.3. Tiempo de uso del procesador después del sleep
declare -i tiempoCPU2=`cat /proc/uptime | cut -f1 -d " " | sed 's/\.//'`

# 4.4. Cálculo del tiempo total de uso del procesador
tiempoCPU=$(($tiempoCPU2-$tiempoCPU1))

# 4.5. Porcentaje de uso del procesador de cada uno de los procesos.
for (( i=0; i<${pidsTotal}; i++ ));
	
	do
		difaux=${diferencia[i]}
		usocpu[i]=$(bc <<< "scale=2;($difaux/$tiempoCPU)*100");

done

# ------------------------------------------------------------------------------

# 5. Se ordenan los procesos según el porcentaje que es la columna 6 (en sentido decreciente) de uso de CPU.

# En este punto no se puede ordenar ya que no se han actualizado los arrays con la información.


# V=($(for (( i=0; i<${usocpu2}; i++ ));
#	do
#		echo "${pid[$i]}" "${user[$i]}" "${prioridad[$i]}" "${virt[$i]}" "${s[$i]}" "${cpu[$i]}" "${mem[$i]}" "${command[$i]}" 
#	done | sort -k6 -nr -k7 -nr | head -10))

# echo ${V[@]}


# ------------------------------------------------------------------------------

# 6. Se muestra la información 

# 6.1. Cabecera 1.
# ------------------

# 6.1.1. Número de procesos
# pidsTotal=${#pids[@]}

printf "${blue}NumeroProcesos: ${normal}$pidsTotal"

# 6.1.2. Uso total de la CPU

usoCPUTotal=`cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}'`

printf "%30s\n" "${blue}UsoCPU: ${normal}$usoCPUTotal"

# 6.1.3. Memoria total
memTotal=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
printf "%30s\n" "${blue}MemoriaTotal: ${yellow}$memTotal ${normal}KB"

# 6.1.4. Memoria libre
memLibre=`cat /proc/meminfo | grep MemFree| awk '{print $2}'`
printf "%30s\n" "${blue}MemoriaLibre: ${yellow}$memLibre ${normal}KB"

# 6.1.5. Memoria utilizada
memUtilizada=$((memTotal-memLibre));
printf "%30s\n" "${blue}MemoriaUtilizada: ${yellow}$memUtilizada ${normal}KB"
echo -e '\n'

# 6.2. Información de los procesos.
# ------------------------------------


for (( i=0; i<${pidsTotal}; i++ ));
	do

# 6.2.1. Muestra PID: pid del proceso

	if [  -f /proc/${pids[i]}/status ]; then
 		pidProceso=${pids[i]}
		pid[i]=$pidProceso
	fi

# 6.2.2. Muestra USER: usuario que invoca el proceso
#sacamos el id del usuario

	if [ -f /proc/${pids[i]}/status ]; then 
		usid=`cat /proc/${pids[i]}/status | grep 'Uid:' | awk '{t=$2;print t}'`
		userid[i]=$usid
	fi

#sacamos el nombre de usuario

	if [ -f /proc/${pids[i]}/status ]; then 
		username=`getent passwd "${userid[i]}" | cut -d: -f1`
		user[i]=$username
	fi

# 6.2.3. Muestra PR: prioridad

	if [ -f /proc/${pids[i]}/stat ]; then 
		prior=`cat /proc/${pids[i]}/stat | awk '{t=$18;print t}'`
		prioridad[i]=$prior
	fi

# 6.2.4. Muestra VIRT: tamaño de la memoria virtual de proceso

	if [ -f /proc/${pids[i]}/stat ]; then 
		memoriaVirtual=`cat /proc/${pids[i]}/stat | awk '{t=$23;print t}'`
		virt[i]=$(($memoriaVirtual/1000))
	fi

# 6.2.5. Muestra S: estado del proceso

	if [ -f /proc/${pids[i]}/stat ]; then 
		state=`cat /proc/${pids[i]}/stat | awk '{t=$3;print t}'`
		s[i]=$state
	fi

# 6.2.6. Muestra %CPU: porcentaje del procesador
#uso total del cpu

		usocpuaux=$(bc <<< "scale=2;${usocpu[i]}");
		cpu[i]=${usocpuaux}

# 6.2.7. Muestra %MEM: porcentaje del uso de memoria
#memoria de cada proceso

	if [ -f /proc/${pids[i]}/stat ]; then 
		mempr=`cat /proc/${pids[i]}/stat | awk '{t=$24;print t}'`
		memPag[i]=$(($mempr * 4))
	fi

#sacamos los porcentajes de uso de la memoria de cada proceso
# Se utiliza el cálculo hecho en el apartado 6.1.4. Memoria de cada proceso

	if [ -f /proc/${pids[i]}/stat ]; then 
		memaux=${memPag[i]}
		memaux2=$(bc <<< "scale=2;$memaux*100/$memTotal");
		mem[i]="$memaux2"
	fi

# 6.2.8. Muestra TIME+: tiempo de ejecución del proceso

	if [ -f /proc/${pids[i]}/stat ]; then 
		tiem=`cat /proc/${pids[i]}/stat | awk '{t=$14+$15;print t}'`
		tiempo[i]=$((tiem))
	
		tmm=$((${tiempo[i]}/100));
		tss=$((${tiempo[i]}-(tmm*100)));
		thh=$(($tmm/60));
		tmmi=$tmm
		tssi=$tss
		if (( $tmm > 60 )); then
			tmmi=$(($tmm%60))		
		fi
		# formato en hh:mm:ss
		time[i]=$(printf '%d:%d.%d\n' $(($thh)) $(($tmmi)) $(($tssi)))
	fi

# 6.2.9. Muestra COMMAND: nombre del programa invocado

	if [ -f /proc/${pids[i]}/stat ]; then 
		programaInvocado=`cat /proc/${pids[i]}/stat | awk '{t=$2;print t}'`
		command[i]=$programaInvocado
	fi

# Fin del bucle FOR
done


# 6.3. Tabla con valores
# -----------------------

printf "%-6s %-10s %-4s %-8s %-4s %-8s %-6s %-9s %-10s\n" PID USER PR VIRT S %CPU %MEM TIME+ COMMAND
printf "${blue}================================================================================"
echo -e " \e[0m"


V=($(for (( i=0; i<${pidsTotal}; i++ ));
	do
		echo "${pid[$i]}" "${user[$i]}" "${prioridad[$i]}" "${virt[$i]}" "${s[$i]}" "${cpu[$i]}" "${mem[$i]}" "${time[$i]}" "${command[$i]}" 
	done | sort -k6 -nr -k7 -nr| head -10))

# echo ${V[@]}
LANG=C printf "%-6s %-10s %-4s %-8s %-4s %-8s %-6s %-9s %-10s\n" ${V[@]}

