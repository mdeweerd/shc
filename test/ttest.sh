#!/bin/bash

shells=('/bin/sh' '/bin/dash' '/bin/bash' '/bin/ksh' '/bin/zsh' '/usr/bin/tcsh' '/bin/csh' '/usr/bin/rc' '/usr/bin/python' '/usr/bin/python2' '/usr/bin/python3')
## Install: sudo apt install dash bash ksh zsh tcsh csh rc

check_opts=('' '-r' '-v' '-D' '-S' '-P')

shc=${1-shc}

txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtrst='\e[0m'    # Text Reset

stat=0
pc=0
fc=0
# Comma separated list of shells that are skipped
SKIP=",${SKIP},ash,"
echo
echo "== Running tests ... (Skip expression: $SKIP)"
for shell in "${shells[@]}"; do
    if [ "${SKIP#*,${shell##*/},}" != "$SKIP" ] ; then
        echo    "===================================================="
        echo -e "=== $shell                :SKIPPED"
        echo    "===================================================="
        continue
    fi
    if [ ! -x "$shell" ] ; then
        echo    "===================================================="
        echo -e "=== $shell                :${txtred}MISSING${txtrst}"
        echo    "===================================================="
        ((fc++))
        stat=1
        continue
    fi
    for opt in "${check_opts[@]}"; do
        tmpd=$(mktemp -d /tmp/shc.XXX.tst)
        tmpf="$tmpd/test.$(basename "$shell")"
        tmpa="$tmpd/a.out"
        tmpl="$tmpd/a.log"
        out=""
        {
            echo '#!'"$shell"
            if [ "${shell#*pyth}" = "$shell" ] ; then
                echo "echo 'Hello World fp:'\$1 sp:\$2"
            else
                echo 'import sys'
                echo 'sys.stdout.write(("Hello World fp:%s sp:%s" % (sys.argv[1],sys.argv[2]))+"\n")'
            fi
        } > "$tmpf"
        # shellcheck disable=SC2086
        "$shc" $opt -f "$tmpf" -o "$tmpa"
        # ls -la "$tmpa"

        expected='Hello World fp:first sp:second'
        if [ "$opt" = "-D" ] ; then
            # Hide debug output
            out=$("$tmpa" first second 2>/dev/null)
            outdbg=$("$tmpa" first second 2>1)
            # TODO: compare dbg output
        else
            out=$("$tmpa" first second 2>&1)
        fi
        if [[ "$out" = "$expected" ]]; then
            echo    "===================================================="
            echo -e "=== $shell [with shc $opt]: ${txtgrn}PASSED${txtrst}"
            echo    "===================================================="
            ((pc++))
            rm -rf "$tmpd"
        else
            echo    "===================================================="
            echo -e "=== $shell [with shc $opt]: ${txtred}FAILED${txtrst}"
            echo    "===================================================="
            echo "  Files kept in '$tmpd'"
            printf "*** Expected Output:\n%s\n" "$expected"
            printf "*** Output:\n%s\n*** End of output\n" "$out"
            echo "$out" > "$tmpl"
            stat=1
            ((fc++))
        fi
    done
done

echo
echo "Test Summary"
echo "------------"

if ((pc>0)); then
    pt="${txtgrn}PASSED${txtrst}"
else
    pt="PASSED"
fi

if ((fc>0)); then
    ft="${txtred}FAILED${txtrst}"
else
    ft="FAILED"
fi

echo -e "$pt: $pc"
echo -e "$ft: $fc"
echo "------------"
echo

if ((stat>0)); then
    echo "EXIT with code $stat"
fi
exit $stat
