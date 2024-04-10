if not(defined("CALLISTO_INCLUDED"))

; Asar compatible file containing information about callisto, can be imported using incsrc as needed

; Marker define to mark that callisto.asm has been included
!CALLISTO_INCLUDED = 1

; Marker define to determine that callisto is assembling a file
!CALLISTO_ASSEMBLING = 1

; Define containing callisto's version number as a string
!CALLISTO_VERSION = "0.2.15"

; Defines containing callisto's version number as individual numbers
!CALLISTO_VERSION_MAJOR = 0
!CALLISTO_VERSION_MINOR = 2
!CALLISTO_VERSION_PATCH = 15

; Define containing path to callisto's module imprint folder
!CALLISTO_MODULES = "C:/Users/Oliver/Documents/Super Mario World/RHRbaserom/.callisto/modules"

; Macro which includes the labels of the given module into the current file
macro include_module(module)
	incsrc "!CALLISTO_MODULES/<module>"
endmacro

; Macro which calls a module label and automatically sets the data bank register
macro call_module(module_label)
	PHB
	LDA.b #<module_label>>>16
	PHA
	PLB
	JSL <module_label>
	PLB
endmacro

; Macro which can be used to error out if the version number of the Callisto that's in use is lower than the one passed to the macro
macro require_callisto_version(major, minor, patch)
if !CALLISTO_VERSION_MAJOR > <major>
elseif !CALLISTO_VERSION_MAJOR == <major> && !CALLISTO_VERSION_MINOR > <minor>
elseif !CALLISTO_VERSION_MAJOR == <major> && !CALLISTO_VERSION_MINOR == <minor> && !CALLISTO_VERSION_PATCH >= <patch>
else
	error "Required Callisto version: <major>.<minor>.<patch>, actual Callisto version: !CALLISTO_VERSION"
endif
endmacro

endif
