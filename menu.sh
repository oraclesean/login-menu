version() {
echo $PROGRAM $VERSION
}

usage()
{
  version
  echo "Usage: "
  echo "$PROGRAM [-i filename] [-c client_name] [-m [ssh|rdp]] [-u username] [-w num] "
  echo " "
  echo "Options: "
  echo "  -c clientname        Client name "
  echo "  -i filename          Absolute/relative location of inventory file (default=./inventory.txt) "
  echo "  -m [ssh, rdp]        Default login method (default=ssh) "
  echo "  -u username          Username for login (default=whoami) "
  echo "  -w <width>           Width of menu (default=110, minimum 80) "
  echo " --nosort              Do not sort the contents of the inventory file "
  echo " "

exit 1
}

print_header() {
# If a value is passed it prints a full header, else print just a divider.
  if [ "${#1}" -gt 0 ]
then printf -v t "%${page_width}s" '='; printf %s "${t// /=}" && printf '\r\n'
     printf "%*s\n" $(( ( $(echo $* | wc -c ) + ${page_width} ) / 2 )) "$1"
else printf -v t "%${page_width}s" '='; printf %s "${t// /=}" && printf '\r\n'
  fi 
}

print_line() {
# Print a menu line
printf "%-20s %3d. %-25s %-50s %-19s \r\n" "$1" "$2" "$3" "$4" "$5"
}

get_vars() {
# Produce ordinals. 
# j is the preceding iteration and is used for formatting headers.
# k is the human-friendly sequence.
j="$(($i-1))"
k="$(($i+1))"

# Trim white space for the individual array values.
hostg[$i]="$(echo ${1} | cut -d'|' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
fname[$i]="$(echo ${1} | cut -d'|' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
descr[$i]="$(echo ${1} | cut -d'|' -f3 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
hname[$i]="$(echo ${1} | cut -d'|' -f4 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
uname[$i]="$(echo ${1} | cut -d'|' -f5 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
lmeth[$i]="$(echo ${1} | cut -d'|' -f6 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
lopts[$i]="$(echo ${1} | cut -d'|' -f7 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# Check to see if the login user is specified:
  if [[ "${#uname[$i]}" -eq 0 ]]
then uname[$i]=$user
else descr[$i]+=" [${uname[$i]}]"
  fi

# Check to see if RDP options are specified:
  if [[ "${#lopts[$i]}" -eq 0 ]]
then lopts[$i]=$log_opts
  fi

# Check to see if the login method is specified:
  if [[ "${#lmeth[$i]}" -eq 0 ]]
then lmeth[$i]=$login_method
  fi

# Create a command based on the connection type. Define the array value based on var=k,
# which will match the menu options presented to users (k starts at 1, i starts at 0)
  if [[ "${lmeth[$i]}" = 'ssh' ]]
then command[$k]="ssh -l ${uname[$i]} ${lopts[$i]} ${hname[$i]}"
else command[$k]="xfreerdp ${lopts[$i]} -u ${uname[$i]} ${hname[$i]}"
  fi
}

show_menu() {
# Read the server file
# $sort is a passed command to enable/disable sorting
IFS=$'\r\n' read -d '\|' -ra lines < <(egrep -v "^#|^$" "$inventory" | eval "${sort}" && printf '\0')

# Is the client defined? Print a header.
  if ! [[ -z "$client" ]]
then print_header $client
  fi

# Process the file.
for i in "${!lines[@]}"
 do get_vars "${lines[$i]}"

    # Is this the first line? Print a separator.
    # Is sorting enabled, and has the group changed? Print a separator.
      if [[ "$i" -eq 0 ]] || ( [[ -z "$nosort" ]] && [[ "${hostg[$i]}" != "${hostg[$j]}" ]] ) 2>/dev/null
    then print_header
      fi

    # Is sorting disabled? Print a line with the category.
    # Is sorting enabled, and has the group changed? Print a line with the category.
    # The additional $i -gt 1 check prevents an error for an invalid array reference.
      if ! [[ -z "$nosort" ]] || [[ "$i" -eq 0 ]] || ( [[ "$i" -gt 0 ]] && [[ "${hostg[$i]}" != "${hostg[$j]}" ]] ) 2>/dev/null
    then print_line "${hostg[$i]}" $k "${fname[$i]}" "${descr[$i]}" "$login_disp"
    else print_line " " $k "${fname[$i]}" "${descr[$i]}" "$login_disp"
      fi
done

# Done. Print a concluding separator:
print_header
printf "%-20s  X.  Exit \r\n \r\n"

echo " "

  if [ ! -z "$command_history" ]
then echo "Command history: $command_history"
else echo " "
  fi

}

read_options() {
local choice
   read -p "Enter an option: (1 - ${k} or X to exit): " choice

        # Was an X entered? Break.
          if [[ "$(echo $choice | tr '[:upper:]' '[:lower:]')" = "x" ]]
        then break

        # Was a valid (1 - k) numeric value entered? Run the command[k].
        elif [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${k}" ]] && [[ "$choice" =~ ^[0-9]+$ ]]
        then 

              if [ -z "$command_history" ]
            then command_history=$choice
            else command_history="$command_history, $choice"
              fi

              if ! eval "${command[$choice]}"
            then echo " "
                 echo "The command: ${command[$choice]} failed!"
                 exit 1
              fi

        # Invalid option.
        else echo "Invalid option"
             sleep 3
          fi
}

# Set variables.
PROGRAM=`basename $0`
VERSION=1.0
client=
inventory="./inventory.txt"
login_method=ssh
sort="sort -bu"
nosort=
user=$(whoami)
page_width=110

# Parse the command line.
while [[ $# -gt 0 ]]
do
option="$1"

case $option in
    -c) client="$2"
    shift; shift ;;
    -i) inventory="$2"
    shift; shift ;;
    -m) login_method="$(echo $2 | tr '[:upper:]' '[:lower:]')"
    shift; shift ;;
    -u) user="$2"
    shift; shift ;;
    -w) page_width="$2"
    shift; shift ;;
    --nosort) sort="egrep '.$'"
              nosort="Y"
    shift ;;
    *) usage
    shift ;;
esac
done

# Check command line values
  if ! [[ -f "$inventory" ]] && ! [[ -r "$inventory" ]]
then echo "The inventory file $inventory does not exist or is not readable."
     exit 99
  fi

  if [[ "$login_method" != "ssh" ]] && [[ "$login_method" != "rdp" ]]
then echo "$login_method is not a valid default login method (ssh, rdp)"
     exit 99
  fi

  if [[ "$page_width" -lt 80 ]] || ! [[ "$page_width" =~ ^[0-9]+$ ]] # Trap non-numeric values
then echo "Page width must be a numeric value greater than 80"
     exit 99
  fi

while true
   do
      clear
      show_menu
      read_options
 done
