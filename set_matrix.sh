#!/bin/bash
# copyright @ spring_gcf
# WeChat: 15371737886
parse_vlan()
{ 
    switch vlan dump 4096 | 
    while read line
    do
        line_length=`echo ${line}|wc -L`
        if [ ${line_length} -gt 0 ]; then
            echo $line
        else
            break
        fi
    done | 
    sed '1d' | 
    awk '{print $2}' | 
    sed "s/-/0/g"
}

bin2dex(){
    echo $1|awk 'function bin2dec(a,b,i,c){b=length(a);c=0;for(i=1;i<=b;i++){c+=c;if(substr(a,i,1)=="1")c++}return c}{for(j=1;j<=NF;j++)printf("%d%s",bin2dec($j),j!=NF?".":"\n")}'
}

tmp_content=`parse_vlan`

for i in $(seq 1 7)
do
    matrix=0
    for line in `echo $tmp_content | awk '{for(j=1;j<=NF;j++){print $j}}'`
    do
        active=`echo ${line}|cut -c $i`
        if [ ${active} -gt 0 ]; then
            #var_matrix=`echo $(($((2#$matrix))|$((2#$line))))`
            var_matrix=`echo "$(bin2dex $matrix) $(bin2dex $line)"| awk '{print or($1,$2)}'`
            #matrix=`echo "obase=2;$var_matrix"| bc`
            matrix=`echo $var_matrix|awk '{for(i=1;i<=NF;i++){a="";b=$i;while(b){a=b%2 a;b=int(b/2)}printf("%d%s",a,i!=NF?".":"\n")}}'`
        fi
    done
    matrix=`echo $matrix | awk '{printf("%07d\n",$0)}'`
    matrix_rev=`echo $matrix | awk '{for(i=length($0);i>0;i--) {printf substr($0,i,1)}; printf "\n"}'`
    #((var=2#${matrix_rev}))
    var=`bin2dex $matrix_rev`
    #matrix_hex=`echo "obase=16;$var"|bc`
    matrix_hex=`printf %X $var`
    reg_i=`expr $i - 1`
    echo "switch reg w 0x2${reg_i}04 0x${matrix_hex}0003"
    if [ $# -gt 0 ] && [ $1 == "w" ]; then
        switch reg w 0x2${reg_i}04 0x${matrix_hex}0003
    fi
done

