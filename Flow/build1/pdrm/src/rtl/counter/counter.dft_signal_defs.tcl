set_scan_configuration -style multiplexed_flip_flop

set_scan_configuration -chain_count 1

set_dft_signal -view existing_dft -type ScanClock -port [list {clock}] -timing {45 55}

set_dft_signal -view existing_dft -type Reset -port [list {reset}] -active_state 1

