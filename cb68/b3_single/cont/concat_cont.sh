#!/bin/bash
if_fitsin='yes'
if_uvaver='yes'
if_clean='yes'

molecule='cont'

dir_data='../1_fits/'

# 7m information
visnum_7m=$(seq 0 1 1)
head_7m='7m'

visnum_12m=$(seq 0 1 0)
head_12m='12m'

restfreq='102.5546964GHz'

# 1. load FITS visibility to Miriad format
if [ $if_fitsin	== 'yes' ]
then
  # 7m
  for vis_ID in $visnum_7m
  do
      infile=$head_7m'_vis'$vis_ID'_'$molecule
      rm -rf $infile'.miriad'

      fits in=$dir_data$infile'.fits' op='uvin' out=$infile'.miriad'
  done

  # 12m
  for vis_ID in $visnum_12m
  do
      infile=$head_12m'_vis'$vis_ID'_'$molecule
      rm -rf $infile'.miriad'

      fits in=$dir_data$infile'.fits' op='uvin' out=$infile'.miriad'
  done

fi


# 2. convert polarization and concatenate the velocity-regridded Miriad visibilities
if [ $if_uvaver == 'yes' ]
then

    # 7m
    declare -a visarr_7m
    visarr_7m=()

    for vis_ID in $visnum_7m
    do
      infile=$head_7m'_vis'$vis_ID'_'$molecule
	    visarr_7m+=("$infile.miriad")
    done

    #echo ${visarr_7m[*]}

    # concatenate files
    outfile=$head_7m'_'$molecule'.miriad'
    rm -rf $outfile

    uvaver vis=${visarr_7m[*]} options='nocal,nopass,nopol' \
	         stokes=i out=$outfile

#   cp -r $outfile ../../combine/


    # 12m
    declare -a visarr_12m
    visarr_12m=()

    for vis_ID in $visnum_12m
    do
      infile=$head_12m'_vis'$vis_ID'_'$molecule
	    visarr_12m+=("$infile.miriad")
    done
    
    outfile=$head_12m'_'$molecule'.miriad'
    rm -rf $outfile

    uvaver vis=${visarr_12m[*]} options='nocal,nopass,nopol' \
	         stokes=i out=$outfile

#   cp -r $outfile ../../combine/


fi

# 3. clean 
if [ $if_clean == 'yes' ]
then
  rm -rf 7m_vis*
  rm -rf 12m_vis*
fi
