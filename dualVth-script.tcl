##	+----------------------------------------------------------------
##	|	Synthesis and Optimization of Digital Circuits	

##	+----------------------------------------------------------------
##	|	author: Emanuele Garolla, Nicolo Morando		
##	|	group:	1						
##	|	title:	dualVth_Group_1.tcl	
##	+----------------------------------------------------------------
##	| 	Copyright 2015 						
##	+----------------------------------------------------------------

proc leakage_opt {arrivalTime arrTime criticalPaths critPaths slackWin slackWindow} {
set path_HVT_cells "CORE65LPHVT_nom_1.00V_25C.db:CORE65LPHVT/"
set path_LVT_cells "CORE65LPLVT_nom_1.00V_25C.db:CORE65LPLVT/"
set res [list]
set l_temp [list]
set init_clock [clock clicks -milliseconds]
set init_data [list]
set flag 0
set tot_cells 0
set power_start 0
set power_end 0
set time_clock 0
set power_saving 0
set n_lvt 0
set n_hvt 0

set clock_period [get_attribute [get_clock] period]
set first_arrival [get_attribute [get_timing_path] arrival]
set rightEdge [expr $slackWindow]
if { $first_arrival > $arrTime } {
puts "Error on the arrival time , the output will be all 0"
} else {
set power_start [power_tot] 
foreach_in_collection point_cell [get_cells] {
set tot_cells [expr $tot_cells + 1]
set cell_code [get_attribute $point_cell full_name]
set reference_name [get_attribute $point_cell ref_name]
regsub "_LL" $reference_name "_LH" new_name
size_cell $cell_code  $path_HVT_cells$new_name
set n_hvt [expr $n_hvt + 1]
set l_temp [get_attribute [get_timing_path -nworst $critPaths -slack_lesser_than $rightEdge] arrival]
set n_paths [llength $l_temp]
set arrival_temp  [lindex $l_temp 0] 
if { $arrival_temp > $arrTime } { set flag 1 }
if { $n_paths >= $critPaths || $flag == 1 } {
size_cell $cell_code  $path_LVT_cells$reference_name
set n_lvt [expr $n_lvt + 1]
set n_hvt [expr $n_hvt - 1]
}		
set flag 0
}
set power_end [power_tot]
set power_temp [expr $power_start - $power_end ]
set power_saving [expr ($power_temp)/$power_start ]
set fin_clock [clock clicks -milliseconds]
set time_clock [expr round(($fin_clock - $init_clock)/100.0)/10.0]
set n_lvt [expr ($n_lvt * 1.0)/$tot_cells]
set n_hvt [expr ($n_hvt * 1.0)/$tot_cells]
}

lappend res $power_saving
lappend res $time_clock
lappend res $n_lvt
lappend res $n_hvt
return $res
}

proc power_tot {} {
	set report_text ""  ;# Contains the output of the report_power command
	set lnr 18         ;# Leakage info is in the 2nd line from the bottom prima 4
	set wnr 4           ;# Leakage info is the 5 word in the $lnr line 
	set unit 5           ;# measure unit info is the 6 word in the $lnr line 
	redirect -variable report_text {report_power -nosplit}
	set report_text [split $report_text "\n"]

	set value_power [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $wnr]
	set unit_power [lindex [regexp -inline -all -- {\S+} [lindex $report_text [expr [llength $report_text] - $lnr]]] $unit]
	  
	if { $unit_power == "mW" } {
		return [expr $value_power * 1000.0 ]
	} elseif {$unit_power == "uW"} {
		return $value_power
	} elseif {$unit_power == "nW"} {
		return [expr $value_power / 1000.0 ]
	} elseif {$unit_power == "pW"} {
		return [expr $value_power / 1000000.0 ]
	}
}
