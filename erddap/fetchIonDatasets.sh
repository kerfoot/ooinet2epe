#! /bin/bash --
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

PATH=${PATH}:/bin;

app=$(basename $0);

# Usage message
USAGE="
NAME
    $app - download ION NetCDF files via ERDDAP

SYNOPSIS
    $app [h] csvFile

DESCRIPTION
    Parses the comma-separated value file (3 columns) containing the product
    name, resource id and erddap url, respectively and downloads the NetCDF
    file at the specified ERDDAP url.

    -h
        show help message
";

# Default values for options
ERDDAP_BASE_URL='http://erddap-test.oceanobservatories.org:8080/erddap/tabledap/data';
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

if [ "$#" -eq 0 ]
then
    echo "No dataset lists specified." >&2;
    exit 0;
fi

if [ ! -d "$OUT_DIR" ]
then
    echo "Invalid destination: $OUT_DIR" >&2;
    exit 1;
fi

for f in $@
do

    if [ ! -f "$f" ]
    then
        echo "Invalid URL file: $f" >&2;
        continue;
    fi

    # Echo the file
    echo "Fetching Datasets: $f";
    
    # Strip off the path
    baseName=$(basename $f .txt);
    prefix=$(echo $baseName | awk -F'_' 'BEGIN{OFS="-"} {print $1,$2}');
    #echo "Prefix: $prefix";
    
    while read line
    do
    
        product=$(echo $line | awk -F',' 'BEGIN{OFS="-"} {print $1,$2}');
        htmlUrl=$(echo $line | awk -F',' '{print $3}');
        ncUrl=$(echo $htmlUrl | sed 's/\.html/.nc/');
    
        outFile="${OUT_DIR}/${prefix}-${product}.nc";
    
        echo "Fetching URL: $ncUrl";
        echo "Destination : $outFile";
    
        wget $ncUrl -O $outFile;
    
    done < $f
done

