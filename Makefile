#
# Configuration
#配置

# CC
# 指定编译器是GCC
CC=gcc
# Path to parent kernel include files directory
#指定路径的父内核头文件目录
LIBC_INCLUDE=/usr/include
# Libraries
#库
ADDLIB=
# Linker flags
#连接标志
#W1告诉编译器将后面的参数传递给链接器
#-Wl,-Bstatic告诉链接器使用-Bstatic选项，该选项是告诉链接器，对接下来的-l选项使用静态链接
LDFLAG_STATIC=-Wl,-Bstatic
LDFLAG_DYNAMIC=-Wl,-Bdynamic
#指定加载库 cap函数库、TLS加密函数库、crypto加密解密函数库、idn恒等函数库、resolv函数库、sysfs接口函数库等
LDFLAG_CAP=-lcap
LDFLAG_GNUTLS=-lgnutls-openssl
LDFLAG_CRYPTO=-lcrypto
LDFLAG_IDN=-lidn
LDFLAG_RESOLV=-lresolv
LDFLAG_SYSFS=-lsysfs

#
# Options
#选项
#变量定义，设置开关
# Capability support (with libcap) [yes|static|no]
# 支持Capability support (with libcap)功能
USE_CAP=yes
# sysfs support (with libsysfs - deprecated) [no|yes|static]
#不支持虚拟文件系统
USE_SYSFS=no
# IDN support (experimental) [no|yes|static]
#不支持IDN
USE_IDN=no

# Do not use getifaddrs [no|yes|static]
#不要使用getifaddrs 
WITHOUT_IFADDRS=no
# arping default device (e.g. eth0) []
#arping默认设备（例如eth0）
ARPING_DEFAULT_DEVICE=

# GNU TLS library for ping6 [yes|no|static]
#G
USE_GNUTLS=yes
# Crypto library for ping6 
#加密库ping6 共享
# Resolv library for ping6 [yes|static]
#RESOLV库ping6 是静态]
USE_RESOLV=yes
# ping6 source routing (deprecated by RFC5095) [no|yes|RFC3542]
#不使用ping6源路由
ENABLE_PING6_RTHDR=no

# rdisc server (-r option) support [no|yes]
#不支持RDISC服务器
ENABLE_RDISC_SERVER=no

# -------------------------------------
# What a pity, all new gccs are buggy and -Werror does not work. Sigh.
# CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -Werror -g
#-Wstrict-prototypes: 如果函数的声明或定义没有指出参数类型，编译器就发出警告
CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -g
CCOPTOPT=-O3  #顶级优化
GLIBCFIX=-D_GNU_SOURCE
DEFINES=
LDLIB=
#函数库支持动态链接库
FUNC_LIB = $(if $(filter static,$(1)),$(LDFLAG_STATIC) $(2) $(LDFLAG_DYNAMIC),$(2))
#判断每个函数库中是否重复包含函数

# USE_GNUTLS: DEF_GNUTLS, LIB_GNUTLS
# USE_CRYPTO: LIB_CRYPTO
#判断crypto加密解密函数库中的函数是否重复
ifneq ($(USE_GNUTLS),no)
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_GNUTLS),$(LDFLAG_GNUTLS))
	DEF_CRYPTO = -DUSE_GNUTLS
else
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_CRYPTO),$(LDFLAG_CRYPTO))
endif

# USE_RESOLV: LIB_RESOLV

LIB_RESOLV = $(call FUNC_LIB,$(USE_RESOLV),$(LDFLAG_RESOLV))

# USE_CAP:  DEF_CAP, LIB_CAP
#判断CAP函数库中的函数是否重复
ifneq ($(USE_CAP),no)
	DEF_CAP = -DCAPABILITIES
	LIB_CAP = $(call FUNC_LIB,$(USE_CAP),$(LDFLAG_CAP))
endif

# USE_SYSFS: DEF_SYSFS, LIB_SYSFS
#判断SYSFS接口函数库中的函数是否重复
ifneq ($(USE_SYSFS),no)
	DEF_SYSFS = -DUSE_SYSFS
	LIB_SYSFS = $(call FUNC_LIB,$(USE_SYSFS),$(LDFLAG_SYSFS))
endif

# USE_IDN: DEF_IDN, LIB_IDN
#判断IDN恒等函数库中的函数是否重复
ifneq ($(USE_IDN),no)
	DEF_IDN = -DUSE_IDN
	LIB_IDN = $(call FUNC_LIB,$(USE_IDN),$(LDFLAG_IDN))
endif

# WITHOUT_IFADDRS: DEF_WITHOUT_IFADDRS
#判断重复加载
ifneq ($(WITHOUT_IFADDRS),no)
	DEF_WITHOUT_IFADDRS = -DWITHOUT_IFADDRS
endif

# ENABLE_RDISC_SERVER: DEF_ENABLE_RDISC_SERVER
#判断是否使用了
ifneq ($(ENABLE_RDISC_SERVER),no)
	DEF_ENABLE_RDISC_SERVER = -DRDISC_SERVER
endif

# ENABLE_PING6_RTHDR: DEF_ENABLE_PING6_RTHDR

ifneq ($(ENABLE_PING6_RTHDR),no)
	DEF_ENABLE_PING6_RTHDR = -DPING6_ENABLE_RTHDR
ifeq ($(ENABLE_PING6_RTHDR),RFC3542)
	DEF_ENABLE_PING6_RTHDR += -DPINR6_ENABLE_RTHDR_RFC3542
endif
endif

# -------------------------------------
#配置IPv4 IPv6
IPV4_TARGETS=tracepath ping clockdiff rdisc arping tftpd rarpd
IPV6_TARGETS=tracepath6 traceroute6 ping6
TARGETS=$(IPV4_TARGETS) $(IPV6_TARGETS)

CFLAGS=$(CCOPTOPT) $(CCOPT) $(GLIBCFIX) $(DEFINES)
LDLIBS=$(LDLIB) $(ADDLIB)

UNAME_N:=$(shell uname -n)
LASTTAG:=$(shell git describe HEAD | sed -e 's/-.*//')
TODAY=$(shell date +%Y/%m/%d)
DATE=$(shell date --date $(TODAY) +%Y%m%d)
TAG:=$(shell date --date=$(TODAY) +s%Y%m%d)


# -------------------------------------
.PHONY: all ninfod clean distclean man html check-kernel modules snapshot
#检查内核模块在编译过程中产生的中间文件即垃圾文件并加以清除
all: $(TARGETS)

%.s: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -S -o $@
%.o: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -o $@
$(TARGETS): %: %.o
	$(LINK.o) $^ $(LIB_$@) $(LDLIBS) -o $@
#COMPILE.c=$(CC) $(CFLAGS) $(CPPFLAGS) -c
#$< 依赖目标中的第一个目标名字 
# $@ 表示目标
#$^ 所有的依赖目标的集合 
#在$(patsubst %.o,%,$@ )中，把输入后缀为点o的文件转换为不带后缀的可执行文件
#LINK.o把.o文件链接在一起的命令行,缺省值是$(CC) $(LDFLAGS) $(TARGET_ARCH)

# arping
#向相邻主机发送ARP请求
DEF_arping = $(DEF_SYSFS) $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_arping = $(LIB_SYSFS) $(LIB_CAP) $(LIB_IDN)
#ifneq为条件语句开始
ifneq ($(ARPING_DEFAULT_DEVICE),)
DEF_arping += -DDEFAULT_DEVICE=\"$(ARPING_DEFAULT_DEVICE)\"
#在$(ARPING_DEFAULT_DEVICE)中存在结尾空格，在这句话中也会被作为makefile需要执行的一部分
endif

#linux环境下一些实用的网络工具的集合iputils软件包，以下包含的工具：clockdiff， ping / ping6，rarpd，rdisc，tracepath，

# clockdiff
#测算目的主机和本地主机的系统时间差，clockdiff程序由clockdiff.c文件构成。
DEF_clockdiff = $(DEF_CAP)
LIB_clockdiff = $(LIB_CAP)

# ping / ping6
#测试计算机名和计算机的ip地址，验证与远程计算机的连接。ping程序由ping.c ping6.cping_common.c ping.h 文件构成 
DEF_ping_common = $(DEF_CAP) $(DEF_IDN)
DEF_ping  = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_ping  = $(LIB_CAP) $(LIB_IDN)
DEF_ping6 = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS) $(DEF_ENABLE_PING6_RTHDR) $(DEF_CRYPTO)
LIB_ping6 = $(LIB_CAP) $(LIB_IDN) $(LIB_RESOLV) $(LIB_CRYPTO)

#目标文件ping依赖于ping_common.o
ping: ping_common.o
ping6: ping_common.o
ping.o ping_common.o: ping_common.h
ping6.o: ping_common.h in6_flowlabel.h

# rarpd
#逆地址解析协议的服务端程序，rarpd程序由rarpd.c文件构成
DEF_rarpd =
LIB_rarpd =

# rdisc
#路由器发现守护程序，rdisc程序由rdisc.c文件构成。
DEF_rdisc = $(DEF_ENABLE_RDISC_SERVER)
LIB_rdisc =

# tracepath
#与traceroute功能相似，使用tracepath测试IP数据报文从源主机传到目的主机经过的路由，tracepath程序由tracepath.c tracepath6.c traceroute6.c 文件构成。
DEF_tracepath = $(DEF_IDN)
LIB_tracepath = $(LIB_IDN)

# tracepath6
DEF_tracepath6 = $(DEF_IDN)
LIB_tracepath6 =

# traceroute6
DEF_traceroute6 = $(DEF_CAP) $(DEF_IDN)
LIB_traceroute6 = $(LIB_CAP) $(LIB_IDN)

# tftpd
#简单文件传送协议TFTP的服务端程序，tftpd程序由tftp.h tftpd.c tftpsubs.c文件构成。
DEF_tftpd =
DEF_tftpsubs =
LIB_tftpd =
# 目标文件tftpd依赖于tftpsubs.o
tftpd: tftpsubs.o
tftpd.o tftpsubs.o: tftp.h

# -------------------------------------
# ninfod
#生成可执行文件ninfod
ninfod:
	@set -e; \
		if [ ! -f ninfod/Makefile ]; then \#检查是不是存在Makefile普通文件，不存在就创建
			cd ninfod; \
			./configure; \
			cd ..; \
		fi; \
		$(MAKE) -C ninfod  #否则 直接从ninfod目录下读取Makefile

# -------------------------------------
# modules / check-kernel are only for ancient kernels; obsolete
# 内核检查
check-kernel:
ifeq ($(KERNEL_INCLUDE),)         #判断内核是否为空;不为空就设置正确内核;
	@echo "Please, set correct KERNEL_INCLUDE"; false
else
	@set -e; \                 #
	if [ ! -r $(KERNEL_INCLUDE)/linux/autoconf.h ]; then \#判断autoconf.h 是不是存在的一个普通文件。
		echo "Please, set correct KERNEL_INCLUDE"; false; fi
endif

modules: check-kernel                                      
	$(MAKE) KERNEL_INCLUDE=$(KERNEL_INCLUDE) -C Modules #指定modules内核编译的路径

# -------------------------------------
man:
	$(MAKE) -C doc man #生成man帮助手册

html:
	$(MAKE) -C doc html#生成网页格式的帮助文档

clean:
	@rm -f *.o $(TARGETS)  #删除目标文件
	@$(MAKE) -C Modules clean
	@$(MAKE) -C doc clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \#如果ninfod目录下存在 Makefile ,进入并读取
			$(MAKE) -C ninfod clean; \
		fi
#清除生成的文件
distclean: clean 
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod distclean; \
		fi

# -------------------------------------
snapshot:  
        #判断UNAME_N和pleiades的十六进制是否不等
	@if [ x"$(UNAME_N)" != x"pleiades" ]; then echo "Not authorized to advance snapshot"; exit 1; fi
	@echo "[$(TAG)]" > RELNOTES.NEW#将TAG变量里的内容写入RELNOTES.NEW中
	@echo >>RELNOTES.NEW
	@git log --no-merges $(LASTTAG).. | git shortlog >> RELNOTES.NEW #将git log和git shortlog的输出信息重定向到RELOTES.NEW文档里
	@echo >> RELNOTES.NEW 
	@cat RELNOTES >> RELNOTES.NEW #将内容重定项到RELNOTES.NEW 中去
	@mv RELNOTES.NEW RELNOTES   #将RELNOTES.NEW文档重命名为RELNOTES
	@sed -e "s/^%define ssdate .*/%define ssdate $(DATE)/" iputils.spec > iputils.spec.tmp
	@mv iputils.spec.tmp iputils.spec #将inputils.spec.tmp重命名为iputils.spec.
	@echo "static char SNAPSHOT[] = \"$(TAG)\";" > SNAPSHOT.h #重定项技术
	@$(MAKE) -C doc snapshot #生成snapshot的doc文档。
	@$(MAKE) man #执行man命令
	@git commit -a -m "iputils-$(TAG)" #上传文件
	@git tag -s -m "iputils-$(TAG)" $(TAG) #//创建带有说明的标签，用私钥
	@git archive --format=tar --prefix=iputils-$(TAG)/ $(TAG) | bzip2 -9 > ../iputils-$(TAG).tar.bz2#打包，提供别人下载

