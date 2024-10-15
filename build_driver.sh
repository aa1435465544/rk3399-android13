#!/bin/bash
set -x

work_dir=$PWD
#export TOOLCHAIN_UCLIB=./tools/toolchains/mips-gcc520-glibc222/bin/
#export TOOLCHAIN_GUNLIB=${work_dir}/tools/toolchains/mips-gcc520-glibc222/bin/
#chip=p3
uboot_dir=${work_dir}/../rk-android13/u-boot
kernel_dir=${work_dir}/../rk-android13/kernel-5.10
release_dir=${work_dir}/release
rp_rk_dir=${work_dir}/../rk-android13
export BOOT_CONFIG_BACKUP_PATH=${work_dir}/patchs/u-boot
export KERNEL_CONFIG_BACKUP_PATH=${work_dir}/patchs/kernel
export PROJECT_CONFIG_BACKUP_PATH=${work_dir}/patchs/project/
export MODULE_COMPILE_DIR_PREFIX="${work_dir}/tmp"
export RELEASE_PATH="${work_dir}/release_patch"
export KERNEL_MODULE_RELEASE_DIR="${RELEASE_PATH}/kernel_modules/release"
CPU_COUNT=`cat /proc/cpuinfo | grep processor | wc -l`

#declare -x PATH=$TOOLCHAIN_GUNLIB:$PATH
#declare -x ARCH="arm"
#declare -x CROSS_COMPILE="mips-linux-gnu-"


#export CROSS_COMPILE=${TOOLCHAIN_GUNLIB}mips-linux-gnu-



########################################
#
#
#######################################
perpar_all_original_code()
{
	if [ -d sourcecode ];then
		echo -e "has been ready source file\n"
	else 
		echo -e "prepare source file\n"
		mkdir sourcecode
		cd sourcecode
		wget http://git.ingenic.com.cn:8082/bj/repo
		chmod +x repo
		./repo init -u ssh://sz_halley2@119.136.25.25:29418/mirror/linux/manifest
		./repo sync
		if [$? -ne 0];then
			cp -rf ./* ${work_dir}
		fi
	fi

	cd ${work_dir}
	if [ -d release_patch ];then
		echo -e "has been ready release_patch file\n"
	else 
		echo -e "prepare source file\n"
		mkdir -p release_patch/uboot
		mkdir -p release_patch/kernel
		#mkdir release_patch/project
	fi

}

########################################
#
#
#######################################
function kernel_copy_files()
{
	#kernel config
	cp -rf ${KERNEL_CONFIG_BACKUP_PATH}/configs/kernel_config ${kernel_dir}/.config
	#device tree 
	cp -rf ${KERNEL_CONFIG_BACKUP_PATH}/arch/arm64/boot/dts/rockchip/rk3399/rp-rk3399.dts ${kernel_dir}/arch/arm64/boot/dts/rockchip/rk3399/rp-rk3399.dts
	
	cp -rf ${KERNEL_CONFIG_BACKUP_PATH}/drivers/leds/leds-dyx.c ${kernel_dir}/drivers/leds/
	#cp -rf ${KERNEL_CONFIG_BACKUP_PATH}linux/drivers/misc/* ${kernel_dir}/drivers/misc/
}

########################################
#
#
#######################################
function modules_copy_files()
{
	echo "modules copy files"
	#lcd driver
	#cp -rf ${KERNEL_CONFIG_BACKUP_PATH}linux/drivers/lcd/atcom_lcd.c ${kernel_dir}/drivers/misc/atcom_lcd.c
	#cp -rf ${KERNEL_CONFIG_BACKUP_PATH}linux/drivers/lcd/atcom_lcd.h ${kernel_dir}/drivers/misc/atcom_lcd.h

	#keypad 
	#cp -rf ${KERNEL_CONFIG_BACKUP_PATH}linux/drivers/keypad/atcom_keypad.c ${kernel_dir}/drivers/keypad/atcom_keypad.c
	#aw35616
	#cp -rf ${KERNEL_CONFIG_BACKUP_PATH}linux/drivers/aw35616/*  ${kernel_dir}/drivers/misc/


}
########################################
#
#
#######################################
function android_copy_files()
{
	echo "android copy files"
	#kernel config

}
########################################
#
#
#######################################
function boot_copy_files(){
	echo "copy files to uboot"
	#boot config
	cp -rf ${BOOT_CONFIG_BACKUP_PATH}/boot_config ${uboot_dir}/boot/.config
	#cp -rf ${BOOT_CONFIG_BACKUP_PATH}/boot_config ${uboot_dir}/boot/configs/pioneer3_dualenv_spinand_defconfig
	#cp -rf ${BOOT_CONFIG_BACKUP_PATH}/include/configs/* ${uboot_dir}/boot/include/configs/
}
########################################
#
#
#######################################
function compile_boot()
{
	boot_copy_files
	

	cd ${rp_rk_dir}
	if [ $1 = "menuconfig" ]; then 
		cd ${uboot_dir}
		make ARCH=arm menuconfig
        if [ $? -ne 0 ];then
            echo  -e "\033[31m you configure boot menucofig failed\033[5m failed \033[25m!\033[0m \n"
            return 1
        fi
        #qusetion ask compiler man who compile kernel; if want to save this configure as boot configure
        read  -n1 -p " `echo -e "\033[2J\033[1;0H\033[32mDo you want save this config file as default boot configure:\033[0m\nsave: [y/Y] gave_up:[n/N]\n[ ]\b\b"`" save_requestion
        case "$save_requestion" in
            [Yy])
                 cp -rf .config    ${BOOT_CONFIG_BACKUP_PATH}/boot_config
                 if [ $? -eq 0 ];then
                    echo  -e "Has save boot configure for you to ${BOOT_CONFIG_BACKUP_PATH}/boot_config"
                 else
                    echo -e "\033[2J\033[32m I'm sorry for that can't save boot configre to ${BOOT_CONFIG_BACKUP_PATH}/boot_config,but i has do my best !\033[0m"
                 fi
                 sleep 1
                ;;
            *)
                echo -e "\033[32m you gave up save this configure as default boot confiure ! \033[0m\n"
                sleep 1
                ;;
        esac

		cd ${rp_rk_dir}
	fi

	./build.sh uboot 
		
	if [ ! -d ${release_dir}/uboot ]; then
		mkdir -p ${release_dir}/uboot
	fi
	cp -rf ${uboot_dir}/uboot.img ${release_dir}/uboot/
	cp -rf ${uboot_dir}/trust.img ${release_dir}/uboot/

}
########################################
#
#
#######################################
function compile_kernel()
{

	cd ${rp_rk_dir}
	modules_copy_files
	kernel_copy_files

	if [ $1 = "menuconfig" ]; then 
		cd ${kernel_dir}
		make ARCH=arm64 menuconfig
        if [ $? -ne 0 ];then
            echo  -e "\033[31m you configure kernel menucofig failed\033[5m failed \033[25m!\033[0m \n"
            return 1
        fi
        #qusetion ask compiler man who compile kernel; if want to save this configure as boot configure
        read  -n1 -p " `echo -e "\033[2J\033[1;0H\033[32mDo you want save this config file as default kernel configure:\033[0m\nsave: [y/Y] gave_up:[n/N]\n[ ]\b\b"`" save_requestion
        case "$save_requestion" in
            [Yy])
                 cp -rf .config    ${KERNEL_CONFIG_BACKUP_PATH}/configs/kernel_config
                 if [ $? -eq 0 ];then
                    echo  -e "Has save kernel configure for you to ${KERNEL_CONFIG_BACKUP_PATH}/kernel_config"
                 else
                    echo -e "\033[2J\033[32m I'm sorry for that can't save boot configre to ${KERNEL_CONFIG_BACKUP_PATH}/kernel_config,but i has do my best !\033[0m"
                 fi
                 sleep 1
                ;;
            *)
                echo -e "\033[32m you gave up save this configure as default boot confiure ! \033[0m\n"
                sleep 1
                ;;
        esac
		cd ${rp_rk_dir}
	fi
	make kernel;
	#make modules_install
	cp -rf ${kernel_dir}/kernel.img ${release_dir}/kernel/
	cp -rf ${kernel_dir}/resource.img ${release_dir}/kernel/
}
########################################
#
#
#######################################
function compile_android()
{
	kernel_copy_files
	android_copy_files

	cd ${rp_rk_dir_dir}
	./build.sh android
	cd ${android_dir}
	if [ -d ${work_dir}/project/kbuild/4.9.84 ];then
		make dispcam_p3_spinand.glibc-9.1.0-s01a.64.qfn128.demo_wifi_defconfig
		make image-fast -j ${CPU_COUNT}
	else
		make clean
		make dispcam_p3_spinand.glibc-9.1.0-s01a.64.qfn128.demo_wifi_defconfig
		make image -j ${CPU_COUNT}
	fi
		./make_usb_factory_sigmastar.sh
	cp -rf $work_dir/project/image/output/images $work_dir/release_patch/project/
	curl -F "image=@/home/dyx/atcom_sigmaster/release_patch/project/images/SstarUsbImage.bin" http://172.16.1.126/project/
}
########################################
#
#
#######################################
function compile_demo()
{
	cd ${work_dir}/patchs/test/
	if [ ! -d atcom_tools ];then
		mkdir atcom_tools
	fi
	./build.sh

}


#####################################################################################################################
#   Function :
#           compile all kernel modules  and install to ${KERNEL_MODULE_RELEASE_DIR}
#   param:
#           $1: module name
#           $2: module's code path
#           $3: module's output name
#
####################################################################################################################

do_compile_modules()
{
    #printf all param which has been passed

    echo  -e " \n param list is : \n    param1:$1 \n    param2:$2 \n    param3:$3\n"
    sleep 1
    module_name="$1"
    module_code_path="$2"
    module_output_name="$3"

    MODULE_SOURCE_DIR=$module_code_path
    #check whether has dirctory of hardware version's compile
    if [ ! -d ${MODULE_COMPILE_DIR_PREFIX} ];then
        mkdir -p ${MODULE_COMPILE_DIR_PREFIX}
    else
        rm -rf ${MODULE_COMPILE_DIR_PREFIX}/$module_name #hardware_version
    fi

    #check moudle's source file has exist in ${MODULE_SOURCE_DIR}
    if [ ! -d ${MODULE_SOURCE_DIR} ];then
        compile_modules_failed_reason="no ${MODULE_SOURCE_DIR} are ready for $module_name's,please check you has write that driver !"
        do_compile_all_module=1
        return $do_compile_all_module
    fi

    content=`ls $folder`
    if [ "$content" = "" ];then
        compile_modules_failed_reason="no $module_name's code for you, please check ${MODULE_SOURCE_DIR},did has any files"
        do_compile_all_module=1
        return $do_compile_all_module
    fi

    #copy hardware version code to compile directory
    cp -rf ${MODULE_SOURCE_DIR} ${MODULE_COMPILE_DIR_PREFIX}/$module_name
    if [ $? -ne 0 ];then
        compile_modules_failed_reason=" cp -rf ${MODULE_SOURCE_DIR} ${MODULE_COMPILE_DIR_PREFIX} failed "
        do_compile_all_module=1
        return $do_compile_all_module
    fi

    makefile_path=${MODULE_COMPILE_DIR_PREFIX}/$module_name/Makefile

    #begain to compile hardware version for you, param 1: kernel directory param 2: modules install path
    chmod 777 ${makefile_path}

    make -f ${makefile_path}  KERNEL_SRC=${kernel_dir} INSTALL_PATH=${KERNEL_MODULE_RELEASE_DIR} MODULE_PATH=${MODULE_COMPILE_DIR_PREFIX}/$module_name
    if [ $? -ne 0 -o ! -f ${MODULE_COMPILE_DIR_PREFIX}/$module_name/$module_output_name  ];then
        compile_modules_failed_reason="compile $module_output_name in ${MODULE_SOURCE_DIR} failed !"
        do_compile_all_module=1
        return $do_compile_all_module
    fi

    make -f ${makefile_path}  KERNEL_SRC=${kernel_dir} INSTALL_PATH=${KERNEL_MODULE_RELEASE_DIR} MODULE_PATH=${MODULE_COMPILE_DIR_PREFIX}/$module_name install
    if [ $? -ne 0 -o ! -f ${KERNEL_MODULE_RELEASE_DIR}/$module_output_name  ];then
        compile_modules_failed_reason="install $module_output_name to ${KERNEL_MODULE_RELEASE_DIR} failed !"
        do_compile_all_module=1
        return $do_compile_all_module
    fi

    #added by yuemalin for copy module to /tftpboot
    #${STRIP} --strip-unneeded ${KERNEL_MODULE_RELEASE_DIR}/$module_output_name
    cp -rf ${KERNEL_MODULE_RELEASE_DIR}/$module_output_name /tftpboot/
    return $do_compile_all_module
}

##################################################################################################
#   Function:
#       cross compiled all kernel modules which is atcom's special driver
#
##################################################################################################

compile_modules()
{
    #initialized module compile status to succesful
    do_compile_all_module=0

    #chech whether has mouldes release dirctory
    if [ ! -d ${KERNEL_MODULE_RELEASE_DIR} ];then
        mkdir -p ${KERNEL_MODULE_RELEASE_DIR}
        chmod 777 ${KERNEL_MODULE_RELEASE_DIR} -R
    else
        rm -rf  ${KERNEL_MODULE_RELEASE_DIR}/*
    fi
	cd ${work_dir}

<<!
    #compiled hardversion of atcom's
    do_compile_modules hardware_version ${work_dir}/patchs/kernel/linux/drivers/char/hardware_version atcom_version.ko
    if [ $? -ne 0 ];then
        rm -rf ${MODULE_COMPILE_DIR_PREFIX}/hardware_version
        do_compile_all_module=1
        return $do_compile_all_module
    else
        rm -rf ${MODULE_COMPILE_DIR_PREFIX}/hardware_version
    fi
!
    #compiled rgb lcd of atcom's
    do_compile_modules lcd ${work_dir}/patchs/kernel/linux/drivers/lcd/ atcom_lcd.ko
    if [ $? -ne 0 ];then
        rm -rf ${MODULE_COMPILE_DIR_PREFIX}/lcd
        do_compile_all_module=1
        return $do_compile_all_module
    else
        rm -rf ${MODULE_COMPILE_DIR_PREFIX}/lcd
    fi

<<!
    #compiled atcom's keypad
    do_compile_modules atcom_keypad  ${work_dir}/patchs/kernel/linux/drivers/keypad atcom_keypad.ko
    if [ $? -ne 0 ];then
         rm -rf ${MODULE_COMPILE_DIR_PREFIX}/atcom_keypad
        do_compile_all_module=1
        return $do_compile_all_module
    else
          rm -rf ${MODULE_COMPILE_DIR_PREFIX}/atcom_keypad
    fi
!
    return $do_compile_all_module
}

########################################
#
#
#######################################
function compile_wifi()
{
	export LINUXDIR=${kernel_dir}
	export KERNEL_SRC=${kernel_dir}
	export OUT_OF_TREE_BUILD=y

	cd ${KERNEL_CONFIG_BACKUP_PATH}/linux/drivers/net/wireless/bcmdhd
	make clean
	make all
	${CROSS_COMPILE}strip ${KERNEL_CONFIG_BACKUP_PATH}/linux/drivers/net/wireless/bcmdhd/bcmdhd.ko
	cp ${KERNEL_CONFIG_BACKUP_PATH}/linux/drivers/net/wireless/bcmdhd/bcmdhd.ko $work_dir/release_patch/kernel_modules/
}
########################################
#
#
#######################################
#function compile_kernel_module()
#{
#
#}
########################################
#
#
#######################################
docs="Usage: \
\n\tbash $0 [options] \
\nOptions: \
\n\t-m MODULE: compile module(boot kernel_menuconfig kernel xxx.ko rootfs demo), required\
\n\t-all ALL: compile all module, required\
\n\t-h HELP: show help, required\
\nExample: \
\n\t bash $0 -m [boot][boot_menuconfig][kernel_menuconfig][kernel][xxx.ko][project][demo]\n
\n\t bash $0 -all \n
\n\t bash $0 -h  "

usage(){
	echo -e ${docs} >&2
	exit 1
}

if [ $# -eq 0 ] || [ $1 == -h ]; then usage; fi

echo ${MODULE_COMPILE_DIR_PREFIX}
perpar_all_original_code

all_module=""
module=""
while getopts ":m:ha" opt;do
	case "$opt" in
		"a") 
			all_module="y"
			;;
		"m")
			module=$OPTARG
			;;
		"h") 
			usage
			;;
		"?")
			echo "Invalid optin: -$OPTARG" >&2
			usage
			;;
	esac
done
echo -e "\033[32m all_module=$all_module module=$module \033[0m\n "

if [ ${all_module} = y ]; 
	then echo "compile all module"
	elif [ !${module} ]; then 
	case "${module}" in
		"boot")
		compile_boot
		;;
		"boot_menuconfig")
		compile_boot "menuconfig"
		;;
		"kernel_menuconfig")
		compile_kernel "menuconfig"
		;;
		"kernel")
		compile_kernel
		;;
		"android")
		compile_android
		;;
		"demo")
		compile_demo
		;;
		"modules")
		compile_modules
		;;
		"wifi")
		compile_wifi
		;;
	esac

fi













