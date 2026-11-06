# The boot layer of an appliance (handbook decision 0052), built with
# "bt-layer --boot APPLIANCE" on top of the appliance's layer: the kernel,
# initrd, firmware, bootloaders and installer of plans/keel-boot in common,
# GRUB's overlay and conf. The ISO is made from the appliance's chain with
# this layer on top; the container template is assembled without it, and
# keel assemble refuses a template that has any of these packages.
#
# turnkey.mk puts turnkey.d first: bt-layer applies only what the parent
# did not, so this layer runs keel-boot and the turnkey.d steps every
# layer needs.
#
# The name of the machine: bt-layer --boot gives HOSTNAME, the name of the
# appliance's rootfs, and turnkey.d/hostname writes it and "127.0.1.1
# HOSTNAME" again. This product has no changelog, so turnkey.mk does not
# seal the name; the hook below does, with the seal-hostname of common the
# appliance's layer used: the appliance name of /etc/keel_version, which
# the boot layer inherits, and no 127.0.1.1 line. Without it an ISO
# installed a machine named "boot" (2026-11-06). As turnkey.mk asks, the
# first line of the hook is empty, and turnkey.mk adds its own after it.
COMMON_OVERLAYS = keel-boot
COMMON_CONF = keel-boot

define root.patched/post

	$(FAB_PATH)/common/mk/turnkey/seal-hostname $O/root.patched
endef

include $(FAB_PATH)/common/mk/turnkey.mk
