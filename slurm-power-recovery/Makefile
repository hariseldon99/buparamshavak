PREFIX ?= /usr/local
LIBEXECDIR ?= $(PREFIX)/libexec/slurm-power-recovery

ifeq ($(PREFIX),/usr)
    SYSTEMD_UNIT_DIR ?= /lib/systemd/system
else
    SYSTEMD_UNIT_DIR ?= /etc/systemd/system
endif

all: src/slurm-power-recovery.service
	@echo "Source compilation complete. Ready for target layout install."

src/slurm-power-recovery.service: src/slurm-power-recovery.service.in Makefile
	sed 's|@LIBEXECDIR@|$(LIBEXECDIR)|g' $< > $@

install:
	install -d $(DESTDIR)$(LIBEXECDIR)
	install -m 0755 src/slurm-recovery-hook.sh $(DESTDIR)$(LIBEXECDIR)/slurm-recovery-hook.sh
	install -d $(DESTDIR)$(SYSTEMD_UNIT_DIR)
	sed 's|@LIBEXECDIR@|$(LIBEXECDIR)|g' src/slurm-power-recovery.service.in > $(DESTDIR)$(SYSTEMD_UNIT_DIR)/slurm-power-recovery.service
	chmod 0644 $(DESTDIR)$(SYSTEMD_UNIT_DIR)/slurm-power-recovery.service

uninstall:
	rm -f $(DESTDIR)$(LIBEXECDIR)/slurm-recovery-hook.sh
	rmdir $(DESTDIR)$(LIBEXECDIR) 2>/dev/null || true
	rm -f $(DESTDIR)$(SYSTEMD_UNIT_DIR)/slurm-power-recovery.service

clean:
	rm -f src/slurm-power-recovery.service

.PHONY: all install uninstall clean

