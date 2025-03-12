FNAME_C ?= show_slab_allocator
ifeq ($(FNAME_C),)
  $(error ERROR: you Must pass the C file like this: \
  make FNAME_C=csrc-filename-without-.c target-name)
else ifneq ("$(origin FNAME_C)", "command line")
  $(info FNAME_C=$(FNAME_C))
endif

KDIR ?= /lib/modules/$(shell uname -r)/build

#CC     := $(CROSS_COMPILE)gcc
CC    := clang
STRIP := ${CROSS_COMPILE}strip

PWD            := $(shell pwd)
obj-m          += ${FNAME_C}.o
show_slab_allocator-objs := main.o

MYDEBUG ?= n
DBG_STRIP := y
ifeq (${MYDEBUG}, y)
# https://www.kernel.org/doc/html/latest/kbuild/makefiles.html#compilation-flags
# EXTRA_CFLAGS deprecated; use ccflags-y
  ccflags-y   += -DDEBUG -g -ggdb -gdwarf-4 -Wall -fno-omit-frame-pointer
  DBG_STRIP := n
else
  ccflags-y   += -UDEBUG -Wall
endif

# We always keep the dynamic debug facility enabled; this allows us to dynamically
# turn on/off debug printk's later... To disable it simply comment out the following line
ccflags-y   += -DDYNAMIC_DEBUG_MODULE
KMODDIR ?= /lib/modules/$(shell uname -r)

# Gain access to kernel configs (the '-' says 'continue on error')
-include $(KDIR)/.config

# Strip the module? Note:
# a) Only strip debug symbols else it won't load correctly
# b) WARNING! Don't strip modules when using CONFIG_MODULE_SIG* crytographic security
ifdef CONFIG_MODULE_SIG
  DBG_STRIP := n
endif
ifdef CONFIG_MODULE_SIG_ALL
  DBG_STRIP := n
endif
ifdef CONFIG_MODULE_SIG_FORCE
  DBG_STRIP := n
endif


all:
	@echo
	@echo '--- Building : KDIR=${KDIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} ccflags-y="${ccflags-y}" MYDEBUG=${MYDEBUG} DBG_STRIP=${DBG_STRIP} ---'
	@${CC} --version|head -n1
	@echo
	make -C $(KDIR) M=$(PWD) modules
	if [ "${DBG_STRIP}" = "y" ]; then \
	   ${STRIP} --strip-debug ${FNAME_C}.ko ; \
	fi
install:
	@echo
	@echo "--- installing ---"
	@echo " [First, invoking the 'make' ]"
	make
	@echo
	@echo " [Now for the 'sudo make install' ]"
	sudo make -C $(KDIR) M=$(PWD) modules_install
	sudo depmod
	@echo " [If !debug and !(module signing), stripping debug info from ${KMODDIR}/extra/${FNAME_C}.ko]"
	if [ "${DBG_STRIP}" = "y" ]; then \
           sudo ${STRIP} --strip-debug ${KMODDIR}/extra/${FNAME_C}.ko ; \
	fi
dt:
ifeq (,$(shell which dtc))
	$(error ERROR: install the DTC compiler first)
endif
	@echo "--- compiles the Device Tree Blob (DTB) from the DTS (ARM/PPC/etc) ---"
	dtc -@ -I dts -O dtb -o $(FNAME_C).dtbo $(FNAME_C).dts
	# DTBO - Device Tree Blob Overlay
nsdeps:
	@echo "--- nsdeps (namespace dependencies resolution; for possibly importing ns's) ---"
	make -C $(KDIR) M=$(PWD) nsdeps
clean:
	@echo
	@echo "--- cleaning ---"
	@echo
	make -C $(KDIR) M=$(PWD) clean
# from 'indent'; comment out if you want the backup kept
	rm -f *~ *.dtb

# Any usermode programs to build? Insert the build target(s) below


#--------------- More (useful) targets! -------------------------------
INDENT := indent

# code-style : "wrapper" target over the following kernel code style targets
code-style:
	make indent
	make checkpatch

# indent- "beautifies" C code - to conform to the the Linux kernel
# coding style guidelines.
# Note! original source file(s) is overwritten, so we back it up.
indent:
ifeq (,$(shell which indent))
	$(error ERROR: install indent first)
endif
	@echo
	@echo "--- applying kernel code style indentation with indent ---"
	@echo
	mkdir bkp 2> /dev/null; cp -f *.[chsS] bkp/
	${INDENT} -linux --line-length95 *.[chsS]
	  # add source files as required

# Detailed check on the source code styling / etc
checkpatch:
	make clean
	@echo
	@echo "--- kernel code style check with checkpatch.pl ---"
	@echo
	$(KDIR)/scripts/checkpatch.pl --no-tree -f --max-line-length=95 *.[ch]
	  # add source files as required

#--- Static Analysis
# sa : "wrapper" target over the following kernel static analyzer targets
sa:
	make sa_sparse
	make sa_gcc
	make sa_flawfinder
	make sa_cppcheck

# static analysis with sparse
sa_sparse:
ifeq (,$(shell which sparse))
	$(error ERROR: install sparse first)
endif
	make clean
	@echo
	@echo "--- static analysis with sparse ---"
	@echo
# If you feel it's too much, use C=1 instead
# NOTE: deliberately IGNORING warnings from kernel headers!
	make -Wsparse-all C=2 CHECK="/usr/bin/sparse --os=linux --arch=$(ARCH)" -C $(KDIR) M=$(PWD) modules 2>&1 |egrep -v "^\./include/.*\.h|^\./arch/.*\.h"

# static analysis with gcc
sa_gcc:
	make clean
	@echo
	@echo "--- static analysis with gcc ---"
	@echo
	make W=1 -C $(KDIR) M=$(PWD) modules

# static analysis with flawfinder
sa_flawfinder:
ifeq (,$(shell which flawfinder))
	$(error ERROR: install flawfinder first)
endif
	make clean
	@echo
	@echo "--- static analysis with flawfinder ---"
	@echo
	flawfinder *.[ch]

# static analysis with cppcheck
sa_cppcheck:
ifeq (,$(shell which cppcheck))
	$(error ERROR: install cppcheck first)
endif
	make clean
	@echo
	@echo "--- static analysis with cppcheck ---"
	@echo
	cppcheck -v --force --enable=all -i .tmp_versions/ -i *.mod.c -i bkp/ --suppress=missingIncludeSystem .

# Packaging: just generates a tar.xz of the source as of now
tarxz-pkg:
	rm -f ../${FNAME_C}.tar.xz 2>/dev/null
	make clean
	@echo
	@echo "--- packaging ---"
	@echo
	tar caf ../${FNAME_C}.tar.xz *
	ls -l ../${FNAME_C}.tar.xz
	@echo '=== package created: ../$(FNAME_C).tar.xz ==='
	@echo '        TIP: When extracting, to extract into a directory with the same name as the tar file, do this:'
	@echo '              tar -xvf ${FNAME_C}.tar.xz --one-top-level'

help:
	@echo '=== Makefile Help : additional targets available ==='
	@echo
	@echo 'TIP: Type make <tab><tab> to show all valid targets'
	@echo 'FYI: KDIR=${KDIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} ccflags-y="${ccflags-y}" MYDEBUG=${MYDEBUG} DBG_STRIP=${DBG_STRIP}'

	@echo
	@echo '--- 'usual' kernel LKM targets ---'
	@echo 'typing "make" or "all" target : builds the kernel module object (the .ko)'
	@echo 'install     : installs the kernel module(s) to INSTALL_MOD_PATH (default here: /lib/modules/$(shell uname -r)/).'
	@echo '            : Takes care of performing debug-only symbols stripping iff MYDEBUG=n and not using module signature'
	@echo 'dt          : compiles the Device Tree Blob (DTB) from the DTS file (applicable to ARM, PPC, RISC-V, etc)'
	@echo 'nsdeps      : namespace dependencies resolution; for possibly importing namespaces'
	@echo 'clean       : cleanup - remove all kernel objects, temp files/dirs, etc'

	@echo
	@echo '--- kernel code style targets ---'
	@echo 'code-style : "wrapper" target over the following kernel code style targets'
	@echo ' indent     : run the $(INDENT) utility on source file(s) to indent them as per the kernel code style'
	@echo ' checkpatch : run the kernel code style checker tool on source file(s)'

	@echo
	@echo '--- kernel static analyzer targets ---'
	@echo 'sa         : "wrapper" target over the following kernel static analyzer targets'
	@echo ' sa_sparse     : run the static analysis sparse tool on the source file(s)'
	@echo ' sa_gcc        : run gcc with option -W1 ("Generally useful warnings") on the source file(s)'
	@echo ' sa_flawfinder : run the static analysis flawfinder tool on the source file(s)'
	@echo ' sa_cppcheck   : run the static analysis cppcheck tool on the source file(s)'
	@echo 'TIP: use Coccinelle as well: https://www.kernel.org/doc/html/v6.1/dev-tools/coccinelle.html'

	@echo
	@echo '--- kernel dynamic analysis targets ---'
	@echo 'da_kasan   : DUMMY target: this is to remind you to run your code with the dynamic analysis KASAN tool enabled; requires configuring the kernel with CONFIG_KASAN On, rebuild and boot it'
	@echo 'da_lockdep : DUMMY target: this is to remind you to run your code with the dynamic analysis LOCKDEP tool (for deep locking issues analysis) enabled; requires configuring the kernel with CONFIG_PROVE_LOCKING On, rebuild and boot it'
	@echo 'TIP: Best to build a debug kernel with several kernel debug config options turned On, boot via it and run all your test cases'

	@echo
	@echo '--- misc targets ---'
	@echo 'tarxz-pkg  : tar and compress the LKM source files as a tar.xz into the dir above; allows one to transfer and build the module on another system'
	@echo '        TIP: When extracting, to extract into a directory with the same name as the tar file, do this:'
	@echo '              tar -xvf ${FNAME_C}.tar.xz --one-top-level'
	@echo '--- Tips ---'
	@echo '  If the build fails with a (GCC compiler failure) message like'
	@echo '   unrecognized command-line option ‘-ftrivial-auto-var-init=zero’'
	@echo '  it's likely that you're using an older GCC. Try installing gcc-12 (or later),'
	@echo '  change this Makefile CC variable to "gcc-12" (or whatever) and retry'
	@echo
	@echo 'help       : this help target'
