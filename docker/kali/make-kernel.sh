#!/bin/bash
timestamp=$(date +"%Y%m%d-%H%M%S")
label=make-kernel
win_user=$1
kernel_type=$2
kernel_feature=$3
build_cache=${4:+'nocache'}
filename="$label${kernel_type:+-$kernel_type}${kernel_feature:+-$kernel_feature}-$timestamp"

while [ ! -d "/mnt/c/users/$win_user" ]; do
    echo " 


    install to which Windows home directory?

        C:\\users\\__________ 

        choose from:
    " 
    ls -da /mnt/c/users/*/ | tail -n +4 | sed -r -e 's/^\/mnt\/c\/users\/([ A-Za-z0-9]*)*\/+$/\t\1/g'
    read -r -p "
" win_user
done

# docker_vols=$(docker volume ls -q)
tee "$filename.sh" >/dev/null <<'TXT'
#!/bin/bash
win_user=${1}
echo "win_user = $win_user"
kernel_type=${2:-basic}
echo "kernel_type = $kernel_type"
kernel_feature=${3}
echo "kernel_feature = $kernel_feature"
build_cache=${4:+' --no-cache'}
echo "build_cache = $build_cache"
docker_vols=$(docker volume ls -q)
#               ___________________________________________________                 #
#               ||||               Executing ...               ||||                 #
#                -------------------------------------------------                  #
#
                    docker buildx build ${build_cache} \
                    --target dvlp_kernel-output \
                    --output type=local,dest=/mnt/c/users/"${win_user}"/k-cache \
                    --build-arg KERNEL_TYPE="${kernel_type}" \
                    --build-arg KERNEL_FEATURE="${kernel_feature}" \
                    --build-arg REFRESH_REPO=yes \
                    --build-arg WIN_USER="${win_user}" \
                    --build-arg CONFIG_FILE= \
                    --progress=auto \
                    . 2>&1
# 
#                -----------------------------------------------                    #
#               |||||||||||||||||||||||||||||||||||||||||||||||||                   #
#               __________________________________________________                  #
TXT
# copy the command to the log first
eval cat "$filename.sh" 2>&1 | tee --append "$filename.log"
# execute .sh file && log all output
bash "${filename}.sh" "${win_user}" "${kernel_type}" "${kernel_feature}" "${build_cache}" | tee --append "${filename}.log"
# prompt to install newly built kernel
bash ../../kernels/linux/install-kernel.sh "$win_user" latest