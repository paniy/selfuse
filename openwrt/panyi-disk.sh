#!/bin/bash
board=$(cat /tmp/sysinfo/board_name | cut -d , -f2)
DISK="/dev/mmcblk0"
PART="/dev/mmcblk0p2"
fdisk -l ${DISK} >>/dev/null 2>&1 || (echo "找不到磁盘: $DISK - 请测试磁盘名称！" >>/etc/panyi_${board} && exit 1)
MAXSIZEMB=$(printf %s\\n 'unit MB print list' | parted | grep "Disk ${DISK}" | cut -d' ' -f3 | tr -d MB)
if [[ ${MAXSIZEMB} -gt 5120 ]]; then
    echo "[ok] ${PART} 将会扩展到 5120 MB " >>/etc/panyi_${board}
    parted ${DISK} resizepart 2 5120
    [ $? != 0 ] && echo "扩展分区出错了！" >>/etc/panyi_${board}
    e2fsck -y ${PART}
    resize2fs ${PART}
    [ $? = 0 ] && echo "文件系统扩展成功" >>/etc/panyi_${board}
    parted ${DISK} mkpart primary ext2 5120 ${MAXSIZEMB}
    [ $? != 0 ] && echo "新建分区出错了！" >>/etc/panyi_${board}
    mkfs.ext4 /dev/mmcblk0p3
    [ $? != 0 ] && echo "格式化新分区出错了！" >>/etc/panyi_${board}
    # [[ ! -d /panyi ]] && mkdir -p /panyi
    # mount /dev/mmcblk0p3 /panyi
    # if [ $? = 0 ]; then
    #    mkdir -p /panyi/download
    #    echo "新分区完成！" >>/etc/panyi_${board}
    #     dd if=/dev/zero of=/panyi/.swapfilep bs=512M count=2
    #     chown root:root /panyi/.swapfilep
    #     chmod 0600 /panyi/.swapfilep
    #     mkswap /panyi/.swapfilep
    #    swapon /panyi/.swapfilep
    #    [ $? = 0 ] && echo "交换分区分配完成！" >>/etc/panyi_${board}
    # fi
else
    echo "[ok] ${PART} 将会扩展到 ${MAXSIZEMB} MB " >>/etc/panyi_${board}
    parted ${DISK} resizepart 2 ${MAXSIZEMB}
    [ $? != 0 ] && echo "扩展分区出错了！" >>/etc/panyi_${board}
    e2fsck -y ${PART}
    resize2fs ${PART}
    [ $? = 0 ] && echo "文件系统扩展成功" >>/etc/panyi_${board}
fi
