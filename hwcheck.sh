dmidecode -t system | grep Serial
echo ---------------------------------
lscpu | grep "Model name:"
echo ---------------------------------
lshw -short | grep memory | grep 16GiB
lshw -short | grep memory | grep 16GiB | wc -l
echo ----------------------------------
