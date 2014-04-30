#! /bin/bash
#
# USAGE:
#
# ============================================================================
# $RCSfile$
# $Source$
# $Revision$
# $Date$
# $Author$
# $Name$
# ============================================================================
#

PATH=/usr/bin:/bin;

app=$(basename $0);

# Usage message
USAGE="
NAME
    $app - convert NetCDF 3 files to NetCDF 4

SYNOPSIS
    $app [hd DIRECTORY]

DESCRIPTION

    Converts NetCDF3 files to NetCDF 4 Classic.  Created files are writtent to
    the current working directory.

    -h
        show help message
    -d
        destination directory for created NetCDF 4 files
";

# Default values for options
OUT_DIR=$(pwd);

# Process options
while getopts "hd:" option
do
    case "$option" in
        "h")
            echo -e "$USAGE";
            exit 0;
            ;;
        "d")
            OUT_DIR=$OPTARG;
            ;;
        ?)
            echo -e "$USAGE";
            exit 1;
            ;;
    esac
done

# Remove option from $@
shift $((OPTIND-1));

if [ ! -d "$OUT_DIR" ]
then
    echo "Invalid destination: $OUT_DIR" >&2;
    exit 1;
fi

if [ "$#" -eq 0 ]
then
    echo "Please specify a file(s) to convert" >&2;
    exit 1;
fi

for f in $@
do
#    nc3tonc4 $f ${OUT_DIR}/$(basename $f .nc).nc4.nc;
    ncdump $f | ncgen -k 4 -o ${OUT_DIR}/$(basename $f .nc).nc4.nc;
done

