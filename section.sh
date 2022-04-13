#!/bin/bash

# ------------------------------------ BEGIN GLOBAL VARIABLES ------------------------------------ #

# Script directory as absolute path.
declare __DIR

# Script name.
declare __NAME

# Print as block? See function 'usage' for information about blocks.
declare AS_BLOCK

# The character to use as border for the section lines.
declare BORDER_CHAR

# The character to use as filler for the section lines.
declare FILLER_CHAR

# The titles of the section lines.
declare -a TITLES

# The minimum total character length of the section lines.
declare -i MIN_TOTAL_LEN

# The maximum total character length of the section lines.
declare -i MAX_TOTAL_LEN

# The total character length of the section lines. Must be between '$MIN_TOTAL_LEN' and '$MAX_TOTAL_LEN'.
declare -i TOTAL_LEN

# ------------------------------------- END GLOBAL VARIABLES ------------------------------------- #

# ################################################################################################ #

# ------------------------------------- BEGIN PACKAGE - DEBUG ------------------------------------ #

# ############################################################################ #
# Do not print commands and their arguments as they are executed.
#
# Globals:
#   None.
# Arguments:
#   None.
# Outputs:
#   None.
# ############################################################################ #
debug::off() {
  set +x
}

# ############################################################################ #
# Print commands and their arguments as they are executed.
#
# Globals:
#   None.
# Arguments:
#   None.
# Outputs:
#   None.
# ############################################################################ #
debug::on() {
  set -x
}

# -------------------------------------- END PACKAGE - DEBUG ------------------------------------- #

# ################################################################################################ #

# -------------------------------------- BEGIN PACKAGE - ERR ------------------------------------- #

# ############################################################################ #
# Do not exit on error. The return value of a pipeline is the status of the
# last command.
#
# Globals:
#   None.
# Arguments:
#   None.
# Outputs:
#   None.
# ############################################################################ #
err::off() {
  set +eo pipefail
}

# ############################################################################ #
# Exit on error. The return value of a pipeline is the status of the last
# command to exit with a non-zero status, or zero if no command exited with
# a non-zero status.
#
# Globals:
#   None.
# Arguments:
#   None.
# Outputs:
#   None.
# ############################################################################ #
err::on() {
  set -eo pipefail
}

# --------------------------------------- END PACKAGE - ERR -------------------------------------- #

# ################################################################################################ #

# ---------------------------------------- BEGIN FUNCTIONS --------------------------------------- #

# ############################################################################ #
# Prints a section line. One of the following patterns will be used:
#   if a title was provided:
#     $BORDER_CHAR $FILLER_CHAR $TITLE $FILLER_CHAR $BORDER_CHAR
#   if no titles was provided:
#     $BORDER_CHAR $FILLER_CHAR $BORDER_CHAR
#
# The filler chars will be repeated so that the total length of the section
# line matches the value specified in $TOTAL_LEN.
# 
# Globals:
#   TOTAL_LEN
#   BORDER_CHAR
#   FILLER_CHAR
# Arguments:
#   1 - title of the section line, optional.
# Outputs:
#   Writes the section line to stdout.
# ############################################################################ #
print_section_line() {
  local TITLE
  local -i TITLE_LEN
  local -i MAX_TITLE_LEN
  local -i DELTA
  local RIGHT_SIDE
  local -i RIGHT_SIDE_LEN
  local LEFT_SIDE
  local -i LEFT_SIDE_LEN

  TITLE="${1}"
  TITLE_LEN=${#TITLE}

  if [[ $TITLE_LEN -eq 0 ]]; then
    DELTA=$(( $TOTAL_LEN - 4 ))
    LEFT_SIDE="$(repeat_char "${FILLER_CHAR}" $DELTA)"

    echo "${BORDER_CHAR} ${LEFT_SIDE} ${BORDER_CHAR}"
    return
  fi

  MAX_TITLE_LEN=$(( $TOTAL_LEN - 6 ))
  if [[ $TITLE_LEN -gt $MAX_TITLE_LEN ]]; then
    echo "${__NAME}: title '$TITLE' is too long ($TITLE_LEN). Maximum title length is '$MAX_TITLE_LEN' to not exceed total length of '$TOTAL_LEN'."
    return 0
  fi

  DELTA=$(( $MAX_TITLE_LEN - $TITLE_LEN ))
  if [[ $(( DELTA % 2 )) -eq 0 ]]; then
    RIGHT_SIDE_LEN=$(( $DELTA / 2 ))
  else
    RIGHT_SIDE_LEN=$(( ($DELTA + 1) / 2 ))
  fi
  RIGHT_SIDE="$(repeat_char "${FILLER_CHAR}" $RIGHT_SIDE_LEN)"
  LEFT_SIDE_LEN=$(( $DELTA - $RIGHT_SIDE_LEN ))
  LEFT_SIDE="${RIGHT_SIDE:0:$LEFT_SIDE_LEN}"

  echo "${BORDER_CHAR} ${LEFT_SIDE} ${TITLE} ${RIGHT_SIDE} ${BORDER_CHAR}"
}

# ------------------------------------------ BEGIN MAIN ------------------------------------------ #
# ------------------------------------------- END MAIN ------------------------------------------- #

# ############################################################################ #
# Repeats a character.
#
# Globals:
#   None.
# Arguments:
#   1 - char to repeat.
#   2 - total length.
# Outputs:
#   Writes the repeated chars as a string to stdout.
# ############################################################################ #
repeat_char() {
  local CHAR
  local LEN
  local STRING

  CHAR="${1}"
  LEN=$2

  for (( i=0; i < $LEN; i++ )); do
    STRING+="${CHAR}"
  done

  echo "${STRING}"
}

# ----------------------------------------- END FUNCTIONS ---------------------------------------- #

# ################################################################################################ #

# ------------------------------------------ BEGIN MAIN ------------------------------------------ #

# ############################################################################ #
# Convenience function to initialize global variables. This allows for more
# complex value assignments, i.e. function outputs or multi-line operations.
#
# Globals:
#   All.
# Arguments:
#   All command-line arguments.
# Outputs:
#   None.
# ############################################################################ #
init() {
  local LONG_OPTS
  local SHORT_OPTS
  local GETOPT_OUT

  __DIR="$(cd "$(dirname "${0}")" && pwd)"
  __NAME="$(basename "${0}")"
  AS_BLOCK=0
  BORDER_CHAR="#"
  FILLER_CHAR="-"
  TITLES=()
  MIN_TOTAL_LEN=20
  MAX_TOTAL_LEN=1000
  TOTAL_LEN=100

  if [[ "${1}" == "--help" ]]; then
    usage
    exit
  fi

  err::off
  LONG_OPTS="as-block,border:,filler:,length:"
  SHORT_OPTS="bl:"
  GETOPT_OUT="$(getopt --name "${__NAME}" --long "${LONG_OPTS}" --options "${SHORT_OPTS}" -- "$@")"
  if [[ $? -ne 0 ]]; then
    echo "${__NAME}: see 'section --help'"
    exit 1
  fi
  err::on

  eval set -- "${GETOPT_OUT}"
  while true; do
    case "${1}" in
      "--as-block" | "-b")
        AS_BLOCK=1
        shift 1
      ;;

      "--border")
        BORDER_CHAR="${2::1}"
        shift 2
      ;;

      "--filler")
        FILLER_CHAR="${2::1}"
        shift 2
      ;;

      "--length" | "-l")
        TOTAL_LEN=$2

        if [[ $TOTAL_LEN -lt $MIN_TOTAL_LEN ]] || [[ $TOTAL_LEN -gt $MAX_TOTAL_LEN ]]; then
          echo "${__NAME}: total length '$TOTAL_LEN' is out of bounds. Value must be between '$MIN_TOTAL_LEN' and '$MAX_TOTAL_LEN'."
          exit 1
        fi

        shift 2
      ;;

      --)
        shift 1

        while [[ -n "${1}" ]]; do
          TITLES+=("${1}")
          shift 1
        done

        break
      ;;
    esac
  done
}

# ############################################################################ #
# Displays usage of 'main' function.
#
# Globals:
#   __NAME
# Arguments:
#   None.
# Outputs:
#   Writes usage to stdout.
# ############################################################################ #
usage() {
  echo "Usage: "${__NAME}" [OPTION]... [TITLE]..."
  echo "\
Generates a section line that can be used to increase the readability of scripts.
The title must not be longer than TOTAL_LEN - 6 characters.

Mandatory arguments to long options are mandatory for short options too.
  -b, --as-block              print two section lines with 'BEGIN ' and 'END '
                                prepended to the title, respectively.
      --border=BORDER_CHAR    overwrite border character. Default is '$BORDER_CHAR'.
      --filler=FILLER_CHAR    overwrite the filler character. Default is '$FILLER_CHAR'.
  -l, --length=TOTAL_LEN      overwrite the total length. Default is '$TOTAL_LEN'.
                                Must be between '$MIN_TOTAL_LEN' and '$MAX_TOTAL_LEN'."
}

# ############################################################################ #
# Enables error handling and initializes global variables.
#
# Prints a section line for each title in $TITLES. If no title was provided,
# the section line will have no title and will only consist of $FILLER_CHAR.
# If the '--as-block | -b' option was used, each title will have two section
# lines with 'BEGIN ' and 'END ' prepended to the title, respectively.
# 
# Globals:
#   TITLES.
# Arguments:
#   All command-line arguments.
# Outputs:
#   Writes section lines to stdout.
# ############################################################################ #
main() {
  local CUR_TITLE_INDEX
  local MAX_TITLE_INDEX
  local TITLE

  err::on
  init "$@"

  if [[ ${#TITLES[@]} -eq 0 ]]; then
    print_section_line
    exit
  fi

  CUR_TITLE_INDEX=0
  MAX_TITLE_INDEX=$(( ${#TITLES[@]} - 1 ))

  for (( CUR_TITLE_INDEX=0; CUR_TITLE_INDEX<=MAX_TITLE_INDEX; CUR_TITLE_INDEX++ )); do
    TITLE="${TITLES[$CUR_TITLE_INDEX]}"

    if [[ $AS_BLOCK -eq 1 ]]; then
      print_section_line "BEGIN ${TITLE}"
      print_section_line "END ${TITLE}"
    else
      print_section_line "${TITLE}"
    fi

    if [[ $CUR_TITLE_INDEX -lt $MAX_TITLE_INDEX ]]; then
      echo
    fi
  done
}

# ------------------------------------------- END MAIN ------------------------------------------- #

main "$@"
