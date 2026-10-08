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
COMMON_OVERLAYS = keel-boot
COMMON_CONF = keel-boot

include $(FAB_PATH)/common/mk/turnkey.mk
