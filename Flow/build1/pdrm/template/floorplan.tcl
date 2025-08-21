
puts "RM-info: Running script [info script]\n"


# Offsets: routing pitch * 4 (Site width equals routing pitch, height is pitch * 7)
set CORE_UTILIZATION 0.5
set left_right_io2core [expr 0.56*4.0]
set top_bottom_io2core [expr 0.56*4.0]
initialize_floorplan \
  -core_utilization $CORE_UTILIZATION \
  -shape R \
  -orientation N \
  -side_ratio {1.0 1.0} \
  -core_offset "$left_right_io2core $top_bottom_io2core" \
  -flip_first_row false  \
  -coincident_boundary true

connect_pg_net

# create routing blockages at the bottom and top of block area
set lx [lindex [lindex [get_attribute [get_blocks] boundary] 0] 0] 
set ly [lindex [lindex [get_attribute [get_blocks] boundary] 0] 1] 
set ux [lindex [lindex [get_attribute [get_blocks] boundary] 2] 0] 
set uy [lindex [lindex [get_attribute [get_blocks] boundary] 2] 1] 
set core_lx [expr [lindex [lindex [get_attribute [get_core_area] bbox] 0] 0] + 0.5]

# Do standard cell rails first
create_pg_std_cell_conn_pattern rail_pattern -layers Metal1
set_pg_strategy std_cell_strategy -core -pattern {{pattern: rail_pattern } {nets: {VSS VDD}} } -extension {{nets: VDD VSS}  {stop: core_boundary}}  
compile_pg -strategies {std_cell_strategy}


create_pg_mesh_pattern mesh_pattern \
  -parameters {vlayer vwidth vpitch voffset hlayer hwidth hpitch hoffset  } \
  -layers { {{vertical_layer: @vlayer} {width: @vwidth}  {spacing: interleaving} {pitch: @vpitch} {offset: @voffset} {trim: false }} \
            {{horizontal_layer: @hlayer} {width: @hwidth}  {spacing: interleaving} {pitch: @hpitch} {offset: @hoffset} {trim: false }} \
          } \
  -via_rule {{intersection : all} {via_master: default}}

set HSTRAP_LAYER Metal5
set HSTRAP_WIDTH 1.34
set HSTRAP_PITCH 27
set VSTRAP_LAYER Metal4
set VSTRAP_WIDTH 1.4
set VSTRAP_PITCH 28
# Metal5: Width: N routing tracks (0.44+0.46)*N+0.44, Pitch M routing tracks (0.44+0.46)*M
# Metal4: Width: N routing tracks (0.28+0.28)*N+0.28, Pitch M routing tracks (0.28+0.28)*M

set core_lx [expr [lindex [lindex [get_attribute [get_core_area] bbox] 0] 0] + 0.5]
set core_ly [expr [lindex [lindex [get_attribute [get_core_area] bbox] 0] 1] + 0.5]
set cmd "set_pg_strategy mesh_strategy -core -extension {{nets: VDD VSS} {stop: design_boundary_and_generate_pin}} \
  -pattern { {name: mesh_pattern} {nets: VDD VSS} {parameters: $VSTRAP_LAYER [expr $VSTRAP_WIDTH] [expr $VSTRAP_PITCH] $core_lx $HSTRAP_LAYER [expr $HSTRAP_WIDTH] [expr $HSTRAP_PITCH] $core_ly}}"
eval $cmd
# It may seem odd to set a command string and evaluate it, as above,
# but this allows us to use expression strings for the strap width and pitch,
# if desired.

report_pg_via_master_rules
report_pg_strategy_via_rules

puts  "Compile mesh..."
compile_pg -strategies mesh_strategy -via_rule stack_PG

set_app_options -name place.coarse.continue_on_missing_scandef -value true
connect_pg_net
create_placement
set_app_options -name place.coarse.continue_on_missing_scandef -value false
legalize_placement
check_legality

check_pg_connectivity
check_pg_drc

## Place Pins 
place_pins -self

puts "RM-info: Running script [info script]\n"
