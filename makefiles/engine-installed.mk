%-provision-engine.sh:
	cp $(PROVISION_ENGINE_SCRIPT) $@

cirros.img:
	curl -L -o cirros.img $(CIRROS_URL)
	qemu-img check -f qcow2 cirros.img

%-engine-installed.qcow2: %-base.qcow2 %-provision-engine.sh cirros.img
	qemu-img create -f qcow2 -F qcow2 -b $*-base.qcow2 $@.tmp
#	See the remark above about chmod.
	chmod 666 $@.tmp
	virt-customize \
		-a $@.tmp \
		--memsize $(_MEMSIZE) \
		$(_CHANGE_DNF_CACHE_TO_DEV_SHM) \
		--run "$*-provision-engine.sh" \
		$(_RESTORE_REGULAR_DNF_CACHE) \
		--copy-in cirros.img:/var/tmp \
		--run-command "rpm -qa | sort > $(_PKGLIST_PATH)/$(@:.qcow2=-pkglist.txt)" \
		--run-command "setfiles -F -m -v $(SE_CONTEXT) $(PARTITIONS)" \
		--selinux-relabel
	mv $@.tmp $@
	virt-cat -a $@ /tmp/builder.log | tail -20
