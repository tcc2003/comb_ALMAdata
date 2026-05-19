#!/bin/bash

##### Parameters #########################################
if_setheaders='yes'
if_acaim='yesn'
if_12mpb='yesn'
if_uvmodel='yes'
if_acarewt='yes'
if_duplicateALL='yes'
if_finalim='yes'
if_cleanup='yesn'
if_reimmerge='yesn'

# --------------------------------------------------------

# global information -------------------------------------
linerestfreq='100.110195' # in GHz unit

# set the cellsize and dimension for the ACA images
aca_cell=2
aca_imsize=64
aca_niters=10000
aca_cutoff=0.02 # rms: 0.01

# 12m + 7m imaging parameter
tsys=100
alma_cell=0.2
alma_imsize=400
cutoff_alma=0.008 # rms: 0.002
niters_alma=100

# --------------------------------------------------------
# 12m data information
path_12m='./'
name_12m='12m_ch3sh'
pbfwhm_12m='58.14'

# 7m data information
path_7m='./'
name_7m='7m_ch3sh'
pbfwhm_7m='99.79'

##########################################################


##### Reset headers to allow Miriad processing ###########
if [ $if_setheaders == 'yes' ]
then

   # 12m
   pb="gaus("$pbfwhm_12m")"
   puthd in=$name_12m'.miriad'/telescop \
         value='single' type=a
   puthd in=$name_12m'.miriad'/pbtype \
         value=$pb type=a

   # 7m data  
   pb="gaus("$pbfwhm_7m")"
   puthd in=$name_7m'.miriad'/telescop \
	      value='single' type=a
	puthd in=$name_7m'.miriad'/pbtype \
         value=$pb type=a

fi

##########################################################

##### Imaging ACA visibilities ###########################
if [ $if_acaim == 'yes' ]
then
   rm -rf aca.map
   rm -rf aca.beam
   invert vis=$name_7m'.miriad' options=systemp,double \
	       map=aca.map beam=aca.beam cell=$aca_cell imsize=$aca_imsize robust=2.0

   rm -rf aca.model    
   clean map=aca.map beam=aca.beam out=aca.model gain=0.1 \
	      niters=$aca_niters cutoff=$aca_cutoff options=positive

   rm -rf aca.clean
   rm -rf aca.residual
   restor map=aca.map beam=aca.beam model=aca.model \
	       mode=clean out=aca.clean
   restor map=aca.map beam=aca.beam model=aca.model \
          mode=residual out=aca.residual

fi
##########################################################


##### Implment the 12m dish PB to ACA ########
if [ $if_12mpb == 'yes' ]
then

   # regrid the model image to the original imagesize
   rm -rf aca.model.regrid.temp
   regrid in=aca.model tin=aca.map \
          out=aca.model.regrid.temp \
          project=sin

   rm -rf aca.model.regrid.pbcor.temp
   linmos in=aca.model.regrid.temp \
          out=aca.model.regrid.pbcor.temp
	

   # applying ALMA primary beam to ACA+TP clean model
	rm -rf aca.model.regrid.pbcor.demos.temp
	rm -rf aca.model.regrid.pbcor.demos.temp1

   demos map=aca.model.regrid.pbcor.temp vis=$name_12m'.miriad' out=aca.model.regrid.pbcor.demos.temp

	mv aca.model.regrid.pbcor.demos.temp1 aca.model.regrid.pbcor.demos.temp

   
fi

##### Generate visibility model ###########################
if [ $if_uvmodel == 'yes' ]
then

	# simulate visibilities
	rm -rf single_input.alma.uvmodel.miriad
   uvmodel vis=$name_7m'.miriad' model=aca.model.regrid.pbcor.demos.temp \
		     options=replace \
           out=single_input.alma.uvmodel.miriad


   rm -rf temp
   uvputhd vis=single_input.alma.uvmodel.miriad hdvar='telescop' \
           varval='ALMA' type=a out=temp
   rm -rf single_input.alma.uvmodel.miriad
   mv temp single_input.alma.uvmodel.miriad

	outname=single_input.alma.uvmodel.miriad
   pb="gaus("$pbfwhm_12m")"
   puthd in=$outname/telescop \
         value='single' type=a
   puthd in=$outname/pbtype \
         value=$pb type=a
   puthd in=$outname/ctype3 \
         value='VELO-LSR' type=ascii

fi
##########################################################



##### Manually reweight the ACA visibilities ##########
if  [ $if_acarewt == 'yes' ]
then

   echo '##### Reweighting 7m visibility assuming Tsys ='$tsys' Kelvin'
   
   outname=single_input.alma.uvmodel.rewt.miriad
   rm -rf $outname
   uvputhd vis=single_input.alma.uvmodel.miriad hdvar=systemp type=r length=1 \
           varval=$tsys out=$outname
   puthd in=$outname/jyperk value=1.0 type=r

   pb="gaus("$pbfwhm_12m")"
   puthd in=$outname/telescop \
         value='single' type=a
   puthd in=$outname/pbtype \
         value=$pb type=a
   puthd in=$outname/ctype3 \
         value='VELO-LSR' type=ascii

fi

##########################################################



##### Duplicating all visibilities for imaging ###########
if [ $if_duplicateALL == 'yes' ]
then

   rm -rf final_vis
   mkdir final_vis

   cp -r $name_12m'.miriad' ./final_vis/
   cp -r single_input.alma.uvmodel.rewt.miriad ./final_vis/

fi
##########################################################



##### Final imaging ######################################
if [ $if_finalim == 'yes' ]
then

   rm -rf combined.map
   rm -rf combined.beam
   invert "vis=./final_vis/*" options=systemp,double \
          map=combined.map beam=combined.beam cell=$alma_cell imsize=$alma_imsize robust=2.0

   rm -rf combined.model
   clean map=combined.map beam=combined.beam out=combined.model gain=0.1 \
         niters=$niters_alma cutoff=$cutoff_alma options=positive


   rm -rf combined.clean
   rm -rf combined.residual
   restor map=combined.map beam=combined.beam model=combined.model \
          mode=clean out=combined.clean
   restor map=combined.map beam=combined.beam model=combined.model \
          mode=residual out=combined.residual

   puthd in=combined.clean/ctype3 value='VELO-LSR' type=ascii

   rm -rf combined.clean.fits
   fits in=combined.clean op=xyout out=combined.clean.fits
   rm -rf combined.dirty.fits
   fits in=combined.map op=xyout out=combined.dirty.fits
   rm -rf combined.model.fits
   fits in=combined.model op=xyout out=combined.model.fits
   rm -rf combined.residual.fits
   fits in=combined.residual op=xyout out=combined.residual.fits
   rm -rf combined.beam.fits
   fits in=combined.beam op=xyout out=combined.beam.fits


fi
##########################################################



##### Removing meta data #################################
if [ $if_cleanup == 'yes' ]
then
   echo '##### Removing meta data #############'
   rm -rf ./*uvmodel*
   rm -rf ./*regrid*
   rm -rf ./*temp*
   rm -rf ./single_input.miriad
   rm -rf ./single_input*.restor.miriad
   rm -rf ./single_input*.residual.miriad
   rm -rf ./temp.*
   rm -rf ./*.temp
   rm -rf ./uv_random.miriad
   rm -rf ./acatp*
   rm -rf ./intermediate_vis
   rm -rf ./*demos*
   rm -rf ./*deconv*
fi
##########################################################



##### Re-immerge #########################################

if [ $if_reimmerge == 'yes' ]
then


   # Gegrid TP maps
   rm -rf TP.vel.image.regrid.miriad
   regrid in=$name_tp'.image.miriad' tin=combined.clean \
          out=TP.vel.image.regrid.miriad \
          project=sin

   rm -rf combined.clean.reimmerge
   immerge in=combined.clean,TP.vel.image.regrid.miriad factor=1.0 \
	   out=combined.clean.reimmerge

   rm -rf combined.clean.reimmerge.fits
   fits in=combined.clean.reimmerge op=xyout out=combined.clean.reimmerge.fits

fi

##########################################################
