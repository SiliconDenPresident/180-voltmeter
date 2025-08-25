export PDK_DIR=/mnt/designkits/gf180MCU/dk_ncsu/gf180mcu

if [ ! -f ${PWD}/lib.defs ]; then
  cp $PDK_DIR/setup/lib.defs .
fi

# loads versions used for freepdk3
# TODO find newest version that works for everything (no glibc issues)
ml syn/W-2024.09-SP2
ml primesim/W-2024.09-SP1-2
ml icvalidator/W-2024.09-SP2
ml customcompiler/W-2024.09-SP1-2
ml primewave/W-2024.09-SP1-2

# unsure if needed
# ml icvalidator/W-2024.09-SP2
# ml icvalidator/

