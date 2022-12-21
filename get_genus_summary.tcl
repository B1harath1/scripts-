if {$argc < 1} {
	puts "ERROR: REPORT NOT SPECIFIED"
	puts "Usage: tclsh get_genus_report_summary.tcl <report_name>"
	exit
}
set files [lindex $argv 0]
if {[regexp ".gz" $files]} {
	exec gunzip $files
	set files [join [lrange [split $files \.] 0 end-1] \.]
}
set sp ""; set ep ""; set slack ""; set Inv_buf ""; set Combo ""; set total "" ; set higher_cell_delay ""
set i 0 ; set c 0
set f [open $files r]
set data [read $f]
set lines [split $data "\n"]
foreach line $lines {
	if { [lindex $line 0] eq {Start-point} } {
		lappend sp [lindex $line 2]
	}
	if { [lindex $line 0] eq {End-point} } {
		lappend ep [lindex $line 2]
	}
	if { [llength $line ] == 10 || [llength $line] == 11 && [regexp "generic_cell" $line ] || [regexp "memory" $line] } {
		if { [regexp "timing" $line] } {
			if { [regexp "INV" [lindex $line 1] ] || [regexp "BUF" [lindex $line 1]] } {
				incr i
				if { [llength $line ] == 10 } {
					lappend higher_cell_delay [concat [lindex $line 0] [lindex $line 7]]
				} else {
					lappend higher_cell_delay [concat [lindex $line 0] [lindex $line 8]]
				}
			} else {
				incr c 
				if { [llength $line ] == 10 } {
                                        lappend higher_cell_delay [concat [lindex $line 0] [lindex $line 7]]
                                } else {
                                        lappend higher_cell_delay [concat [lindex $line 0] [lindex $line 8]]
                                }

			}
		
		}
	}
	if { [lindex $line 1] eq {slack} } {
		lappend slack [lindex $line 3]
		lappend Inv_buf $i
		lappend Combo [expr $c -1]
		lappend total [expr $i + [expr $c -1]]
		lappend delay [lindex [lsort -index 1 -decreasing $higher_cell_delay] 0]
		set i 0
		set c 0
	}
}
close $f
set fp1 [open "$files.delay.sum" w]
puts $fp1 "---------------------------------------------------------------------------------------------------------------------------------------------"
puts $fp1 "StartPoint\tEndPoint\tComboDepth\tBufInvDepth\tTotalDepth\tHigestCellDelay\tSlack"
puts $fp1 "--------------------------------------------------------------------------------------------------------------------------------------------"
foreach startpoint $sp endpoint $ep combo $Combo buf $Inv_buf Total $total hd $delay Slack $slack {
	puts $fp1 "$startpoint\t$endpoint\t$combo\t$buf\t$Total\t$hd\t$Slack"
}
close $fp1
exec gzip -f $files
puts "pls check $files.delay.sum file"
