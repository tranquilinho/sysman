resource hanfs {

	protocol C;

	startup { wfc-timeout 0; degr-wfc-timeout 120; }

	disk { on-io-error detach; }

	on euler {
		device /dev/drbd1;
		disk /dev/hadisk1/hanfs;
		meta-disk internal;
		address 192.168.130.99:7789;
	}

	on copernico {
		device /dev/drbd1;
		disk /dev/hadisk1/hanfs;
		meta-disk internal;
		address 192.168.130.126:7789;
	}
}
